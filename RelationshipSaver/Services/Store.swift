import Foundation
import Observation

/// The app's single source of truth.
///
/// Storage is a Codable snapshot written to Application Support as JSON. For a
/// personal app holding tens of people this is entirely adequate, and it buys
/// something worth more than scale: no schema migrations, no macro behaviour to
/// debug, and a data file that can be read with any text editor. If the person
/// list ever reaches the thousands this is the piece to replace, and the pure
/// engine above it will not have to change.
@MainActor
@Observable
final class Store {

    private(set) var people: [Person] = []
    private(set) var captures: [Capture] = []
    private(set) var interactions: [Interaction] = []
    var settings: AppSettings = AppSettings() {
        didSet { save() }
    }

    /// The session currently in front of the user.
    private(set) var session: [SessionCard] = []
    private(set) var sessionIndex: Int = 0
    private(set) var sessionID: UUID?
    private(set) var completedThisSession: Int = 0

    private let storeURL: URL
    private let eventLog: EventLog
    private let engine: ResurfaceEngine
    private var isLoaded = false

    // MARK: - Lifecycle

    init(
        directory: URL? = nil,
        engine: ResurfaceEngine = ResurfaceEngine()
    ) {
        let base = directory ?? Store.defaultDirectory()
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        self.storeURL = base.appendingPathComponent("store.json")
        self.eventLog = EventLog(url: base.appendingPathComponent("events.jsonl"))
        self.engine = engine
        load()
    }

    private static func defaultDirectory() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("RelationshipSaver", isDirectory: true)
    }

    private struct Snapshot: Codable {
        var people: [Person]
        var captures: [Capture]
        var interactions: [Interaction]
        var settings: AppSettings
    }

    private func load() {
        defer { isLoaded = true }
        guard let data = try? Data(contentsOf: storeURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        people = snapshot.people
        captures = snapshot.captures
        interactions = snapshot.interactions
        settings = snapshot.settings
    }

    private func save() {
        guard isLoaded else { return }
        let snapshot = Snapshot(
            people: people,
            captures: captures,
            interactions: interactions,
            settings: settings
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    // MARK: - People

    func person(withID id: UUID) -> Person? {
        people.first { $0.id == id }
    }

    var activePeople: [Person] {
        people.filter { !$0.isArchived }.sorted { $0.name < $1.name }
    }

    var archivedPeople: [Person] {
        people.filter(\.isArchived).sorted { $0.name < $1.name }
    }

    func add(_ person: Person) {
        people.append(person)
        eventLog.record(.personAdded, personID: person.id, payload: [
            "intent": person.intent.rawValue,
            "cadenceDays": String(person.cadenceDays)
        ])
        save()
    }

    func update(_ person: Person) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        people[index] = person
        save()
    }

    func delete(_ person: Person) {
        people.removeAll { $0.id == person.id }
        captures.removeAll { $0.personID == person.id }
        save()
    }

    // MARK: - Captures

    var openCaptures: [Capture] {
        captures.filter(\.isOpen)
    }

    /// Captures with nobody attached yet. They wait here rather than being lost.
    var unassignedCaptures: [Capture] {
        openCaptures.filter { $0.personID == nil }.sorted { $0.createdAt > $1.createdAt }
    }

    func openCaptures(for person: Person) -> [Capture] {
        openCaptures.filter { $0.personID == person.id }.sorted { $0.createdAt < $1.createdAt }
    }

    func add(_ capture: Capture) {
        captures.append(capture)
        eventLog.record(.captureCreated, personID: capture.personID, payload: [
            "kind": capture.kind.rawValue,
            "hasDueDate": capture.dueAt == nil ? "false" : "true"
        ])
        save()
    }

    func update(_ capture: Capture) {
        guard let index = captures.firstIndex(where: { $0.id == capture.id }) else { return }
        captures[index] = capture
        save()
    }

    func complete(captureID: UUID, at date: Date = Date()) {
        guard let index = captures.firstIndex(where: { $0.id == captureID }) else { return }
        guard captures[index].isOpen else { return }
        captures[index].completedAt = date
        eventLog.record(.captureCompleted, personID: captures[index].personID, payload: [
            "kind": captures[index].kind.rawValue
        ])
        save()
    }

    // MARK: - Session

    var currentCard: SessionCard? {
        guard sessionIndex < session.count else { return nil }
        return session[sessionIndex]
    }

    var isSessionFinished: Bool {
        !session.isEmpty && sessionIndex >= session.count
    }

    func startSession(now: Date = Date()) {
        let identifier = UUID()
        sessionID = identifier
        session = engine.buildSession(people: people, captures: captures, now: now)
        sessionIndex = 0
        completedThisSession = 0

        eventLog.record(.sessionStarted, sessionID: identifier, payload: [
            "cardCount": String(session.count)
        ])
        for card in session {
            eventLog.record(.personSurfaced, personID: card.person.id, sessionID: identifier, payload: [
                "tier": String(card.reason.tier),
                "isReply": card.reason.isReply ? "true" : "false"
            ])
        }
    }

    private func advance() {
        sessionIndex += 1
        if sessionIndex >= session.count {
            eventLog.record(.sessionCompleted, sessionID: sessionID, payload: [
                "cardCount": String(session.count),
                "actedOn": String(completedThisSession)
            ])
        }
    }

    private func logAction(_ action: CardAction, card: SessionCard, extra: [String: String] = [:]) {
        var payload = extra
        payload["action"] = action.rawValue
        payload["tier"] = String(card.reason.tier)
        payload["isReply"] = card.reason.isReply ? "true" : "false"
        eventLog.record(.actionTaken, personID: card.person.id, sessionID: sessionID, payload: payload)
    }

    /// Closes the capture that put this card on screen, if there was one.
    private func completeSourceCapture(of card: SessionCard) {
        switch card.reason {
        case .replyOwed(let captureID, _, _), .followUpDue(let captureID, _, _):
            complete(captureID: captureID)
        default:
            break
        }
    }

    // MARK: - Card actions

    func markConnected(
        card: SessionCard,
        channel: InteractionChannel = .markedConnected,
        at date: Date = Date()
    ) {
        recordContact(with: card.person, channel: channel, promptedByApp: true, at: date)
        completeSourceCapture(of: card)
        completedThisSession += 1
        logAction(channel == .message ? .message : .markedConnected, card: card)
        advance()
        save()
    }

    /// Used outside a session, from a person's detail screen.
    func recordContact(
        with person: Person,
        channel: InteractionChannel,
        promptedByApp: Bool,
        at date: Date = Date()
    ) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        people[index].lastContactedAt = date
        people[index].snoozedUntil = nil
        interactions.append(Interaction(
            personID: person.id,
            at: date,
            channel: channel,
            promptedByApp: promptedByApp
        ))
        save()
    }

    func snooze(card: SessionCard, duration: SnoozeDuration, now: Date = Date()) {
        guard let index = people.firstIndex(where: { $0.id == card.person.id }) else { return }
        people[index].snoozedUntil = duration.until(from: now)
        people[index].snoozeCount += 1
        logAction(.snoozed, card: card, extra: [
            "duration": duration.rawValue,
            "snoozeCount": String(people[index].snoozeCount)
        ])
        advance()
        save()
    }

    func archive(card: SessionCard) {
        guard let index = people.firstIndex(where: { $0.id == card.person.id }) else { return }
        people[index].isArchived = true
        logAction(.archived, card: card)
        advance()
        save()
    }

    func skip(card: SessionCard) {
        logAction(.skipped, card: card)
        advance()
    }

    func setArchived(_ archived: Bool, for person: Person) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        people[index].isArchived = archived
        if !archived {
            people[index].snoozedUntil = nil
        }
        save()
    }

    // MARK: - Notifications

    func applyNotificationSettings() async {
        guard settings.dailyNudgeEnabled else {
            NotificationScheduler.cancelDailyNudge()
            return
        }
        await NotificationScheduler.scheduleDailyNudge(
            hour: settings.dailyNudgeHour,
            minute: settings.dailyNudgeMinute
        )
        eventLog.record(.notificationScheduled, payload: [
            "hour": String(settings.dailyNudgeHour),
            "minute": String(settings.dailyNudgeMinute)
        ])
    }

    func recordNotificationOpened() {
        eventLog.record(.notificationOpened)
    }
}

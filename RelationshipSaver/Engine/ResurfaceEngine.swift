import Foundation

/// Builds a resurfacing session.
///
/// This is the heart of the product and it is deliberately pure: no storage,
/// no framework types, no clock of its own. Everything it needs is passed in,
/// including `now` and the random number generator, so every rule below is
/// directly testable.
struct ResurfaceEngine {

    struct Configuration {
        /// A session is at most this many cards. Small surfaces beat giant
        /// backlogs, so the stack never refills automatically.
        var sessionLimit: Int = 5
        /// How far ahead birthdays and important dates surface.
        var dateHorizonDays: Int = 7
        /// Someone at or past this share of their cadence is eligible for the
        /// soft pre-overdue slot.
        var softCadenceRatio: Double = 0.8
        /// The serendipity pick is drawn at random from this many of the
        /// longest out of touch remaining people, so it is neither fully
        /// random nor fully predictable.
        var serendipityPoolSize: Int = 5
        /// A floor on how out of touch someone must be to be eligible for the
        /// serendipity pick. Without this the slot surfaces whoever happens to
        /// be left over, including people contacted yesterday, which is noise
        /// rather than serendipity and quickly teaches the user to distrust
        /// the stack.
        var serendipityMinimumDays: Int = 30

        static let `default` = Configuration()
    }

    var configuration: Configuration = .default
    var calendar: Calendar = .current

    init(configuration: Configuration = .default, calendar: Calendar = .current) {
        self.configuration = configuration
        self.calendar = calendar
    }

    /// Convenience for app code, which does not care about seeding.
    func buildSession(people: [Person], captures: [Capture], now: Date) -> [SessionCard] {
        var generator = SystemRandomNumberGenerator()
        return buildSession(people: people, captures: captures, now: now, using: &generator)
    }

    /// Builds the session.
    ///
    /// Tiers are evaluated in order and a person is claimed by the first tier
    /// that wants them, so nobody appears twice. The whole list is truncated
    /// at the end, which is what makes the serendipity pick "only if slots
    /// remain" without any special casing.
    func buildSession<G: RandomNumberGenerator>(
        people: [Person],
        captures: [Capture],
        now: Date,
        using generator: inout G
    ) -> [SessionCard] {
        let limit = configuration.sessionLimit
        guard limit > 0 else { return [] }

        let eligible = people.filter { $0.isEligibleToSurface(at: now) }
        guard !eligible.isEmpty else { return [] }

        var peopleByID: [UUID: Person] = [:]
        for person in eligible {
            peopleByID[person.id] = person
        }

        var claimed = Set<UUID>()
        var cards: [SessionCard] = []

        func claim(_ person: Person, _ reason: SurfaceReason) {
            guard !claimed.contains(person.id) else { return }
            claimed.insert(person.id)
            cards.append(SessionCard(person: person, reason: reason))
        }

        // Tier 1. Replies owed, oldest first.
        for capture in openCaptures(captures, kind: .replyOwed).sorted(by: byCreatedAt) {
            guard let personID = capture.personID, let person = peopleByID[personID] else { continue }
            claim(person, .replyOwed(captureID: capture.id, note: capture.text, since: capture.createdAt))
        }

        // Tier 2. Follow ups that have come due, oldest due first.
        let dueFollowUps = openCaptures(captures, kind: .followUp)
            .filter { $0.isDue(at: now) }
            .sorted(by: byDueDate)
        for capture in dueFollowUps {
            guard let personID = capture.personID, let person = peopleByID[personID] else { continue }
            guard let dueAt = capture.dueAt else { continue }
            claim(person, .followUpDue(captureID: capture.id, note: capture.text, dueAt: dueAt))
        }

        // Tier 3. Birthdays and important dates inside the horizon, soonest first.
        var upcoming: [(person: Person, reason: SurfaceReason, daysAway: Int)] = []
        for person in eligible where !claimed.contains(person.id) {
            guard let next = soonestImportantDate(for: person, now: now) else { continue }
            upcoming.append((person, next.reason, next.daysAway))
        }
        upcoming.sort { lhs, rhs in
            if lhs.daysAway != rhs.daysAway { return lhs.daysAway < rhs.daysAway }
            return lhs.person.id.uuidString < rhs.person.id.uuidString
        }
        for entry in upcoming {
            claim(entry.person, entry.reason)
        }

        // Tier 4. Cadence. Everyone genuinely past their cadence is placed
        // before anyone who is merely approaching it.
        var overdue: [(person: Person, days: Int, overshoot: Int)] = []
        var approaching: [(person: Person, days: Int, ratio: Double)] = []

        for person in eligible where !claimed.contains(person.id) {
            let days = person.daysSinceContact(at: now, calendar: calendar)
            let cadence = max(person.cadenceDays, 1)
            if days >= cadence {
                overdue.append((person, days, days - cadence))
            } else if Double(days) >= Double(cadence) * configuration.softCadenceRatio {
                approaching.append((person, days, Double(days) / Double(cadence)))
            }
        }

        overdue.sort { lhs, rhs in
            if lhs.overshoot != rhs.overshoot { return lhs.overshoot > rhs.overshoot }
            return lhs.person.id.uuidString < rhs.person.id.uuidString
        }
        for entry in overdue {
            claim(entry.person, .pastCadence(daysSinceContact: entry.days))
        }

        approaching.sort { lhs, rhs in
            if lhs.ratio != rhs.ratio { return lhs.ratio > rhs.ratio }
            return lhs.person.id.uuidString < rhs.person.id.uuidString
        }
        for entry in approaching {
            claim(entry.person, .approachingCadence(daysSinceContact: entry.days))
        }

        // Tier 5. One serendipity pick, and only when the rules left room.
        // This is the only path by which a dormant relationship with no
        // cadence pressure ever comes back, which makes it worth protecting.
        //
        // If nobody clears the dormancy floor the session is simply shorter,
        // and an empty session is an honest answer. Padding the stack to look
        // busy is how a calm tool turns into a chore.
        if cards.count < limit {
            let remaining = eligible
                .filter { person in
                    guard !claimed.contains(person.id) else { return false }
                    return person.daysSinceContact(at: now, calendar: calendar)
                        >= configuration.serendipityMinimumDays
                }
                .sorted { lhs, rhs in
                    let lhsDays = lhs.daysSinceContact(at: now, calendar: calendar)
                    let rhsDays = rhs.daysSinceContact(at: now, calendar: calendar)
                    if lhsDays != rhsDays { return lhsDays > rhsDays }
                    return lhs.id.uuidString < rhs.id.uuidString
                }
            let pool = Array(remaining.prefix(max(configuration.serendipityPoolSize, 1)))
            if let pick = pool.randomElement(using: &generator) {
                claim(pick, .serendipity(daysSinceContact: pick.daysSinceContact(at: now, calendar: calendar)))
            }
        }

        return Array(cards.prefix(limit))
    }

    // MARK: - Helpers

    private func openCaptures(_ captures: [Capture], kind: CaptureKind) -> [Capture] {
        captures.filter { $0.isOpen && $0.kind == kind && $0.personID != nil }
    }

    private func byCreatedAt(_ lhs: Capture, _ rhs: Capture) -> Bool {
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private func byDueDate(_ lhs: Capture, _ rhs: Capture) -> Bool {
        let lhsDue = lhs.dueAt ?? lhs.createdAt
        let rhsDue = rhs.dueAt ?? rhs.createdAt
        if lhsDue != rhsDue { return lhsDue < rhsDue }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    /// The nearest birthday or important date inside the horizon, if any.
    private func soonestImportantDate(
        for person: Person,
        now: Date
    ) -> (reason: SurfaceReason, daysAway: Int)? {
        let today = calendar.startOfDay(for: now)
        var best: (reason: SurfaceReason, daysAway: Int)?

        for entry in person.allImportantDates {
            guard let next = entry.monthDay.nextOccurrence(onOrAfter: now, calendar: calendar) else { continue }
            guard let daysAway = calendar.dateComponents([.day], from: today, to: next).day else { continue }
            guard daysAway >= 0, daysAway <= configuration.dateHorizonDays else { continue }
            if best == nil || daysAway < best!.daysAway {
                best = (.dateApproaching(label: entry.label, on: next, daysAway: daysAway), daysAway)
            }
        }
        return best
    }
}

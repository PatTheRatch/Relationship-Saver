import XCTest
@testable import RelationshipSaver

/// Deterministic generator so the serendipity slot is testable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// These tests are the specification for the resurfacing rules in
/// docs/V1_SCOPE.md. If a rule changes there, it changes here first.
final class ResurfaceEngineTests: XCTestCase {

    // A fixed clock and a fixed calendar, so nothing here depends on when or
    // where the suite runs.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    private lazy var now: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 12
        components.hour = 9
        return calendar.date(from: components)!
    }()

    private func engine() -> ResurfaceEngine {
        ResurfaceEngine(configuration: .default, calendar: calendar)
    }

    private func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now)!
    }

    private func daysAhead(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: now)!
    }

    private func person(
        _ name: String,
        cadence: Int = 30,
        lastContacted: Date? = nil,
        created: Date? = nil,
        birthday: MonthDay? = nil,
        snoozedUntil: Date? = nil,
        archived: Bool = false
    ) -> Person {
        Person(
            name: name,
            intent: .maintain,
            cadenceDays: cadence,
            birthday: birthday,
            lastContactedAt: lastContacted,
            snoozedUntil: snoozedUntil,
            isArchived: archived,
            createdAt: created ?? daysAgo(400)
        )
    }

    private func run(
        _ people: [Person],
        _ captures: [Capture] = [],
        seed: UInt64 = 42
    ) -> [SessionCard] {
        var generator = SeededGenerator(seed: seed)
        return engine().buildSession(people: people, captures: captures, now: now, using: &generator)
    }

    private func names(_ cards: [SessionCard]) -> [String] {
        cards.map(\.person.name)
    }

    // MARK: - Priority

    func testReplyOutranksEvenTheMostOverduePerson() {
        let ancient = person("Ancient", lastContacted: daysAgo(400))
        let recent = person("Recent", lastContacted: daysAgo(1))
        let capture = Capture(personID: recent.id, text: "Owe them a reply", kind: .replyOwed)

        let session = run([ancient, recent], [capture])

        XCTAssertEqual(names(session), ["Recent", "Ancient"])
        XCTAssertTrue(session[0].reason.isReply)
        XCTAssertFalse(session[1].reason.isReply)
    }

    func testRepliesAreOrderedOldestFirst() {
        let a = person("A", lastContacted: daysAgo(1))
        let b = person("B", lastContacted: daysAgo(1))
        let newer = Capture(personID: a.id, text: "newer", kind: .replyOwed, createdAt: daysAgo(1))
        let older = Capture(personID: b.id, text: "older", kind: .replyOwed, createdAt: daysAgo(9))

        XCTAssertEqual(names(run([a, b], [newer, older])), ["B", "A"])
    }

    func testDueFollowUpsComeBeforeCadence() {
        let followed = person("Followed", lastContacted: daysAgo(1))
        let overdue = person("Overdue", lastContacted: daysAgo(200))
        let capture = Capture(
            personID: followed.id,
            text: "Ask how the interview went",
            kind: .followUp,
            dueAt: daysAgo(1)
        )

        XCTAssertEqual(names(run([followed, overdue], [capture])), ["Followed", "Overdue"])
    }

    func testFollowUpsNotYetDueDoNotSurface() {
        let person1 = person("Later", lastContacted: daysAgo(1))
        let capture = Capture(
            personID: person1.id,
            text: "Not yet",
            kind: .followUp,
            dueAt: daysAhead(3)
        )

        XCTAssertTrue(run([person1], [capture]).isEmpty)
    }

    func testCompletedCapturesDoNotSurface() {
        let person1 = person("Done", lastContacted: daysAgo(1))
        let capture = Capture(
            personID: person1.id,
            text: "Already handled",
            kind: .replyOwed,
            completedAt: daysAgo(1)
        )

        XCTAssertTrue(run([person1], [capture]).isEmpty)
    }

    // MARK: - Shape of a session

    func testSessionIsCappedAtFive() {
        let people = (0..<9).map { person("P\($0)", lastContacted: daysAgo(100 + $0)) }

        let session = run(people)

        XCTAssertEqual(session.count, 5)
        XCTAssertEqual(names(session), ["P8", "P7", "P6", "P5", "P4"])
    }

    func testPersonAppearsOnceAtTheirHighestPriorityReason() {
        let dual = person("Dual", lastContacted: daysAgo(2))
        let reply = Capture(personID: dual.id, text: "reply", kind: .replyOwed, createdAt: daysAgo(3))
        let followUp = Capture(personID: dual.id, text: "follow up", kind: .followUp, dueAt: daysAgo(1))

        let session = run([dual], [reply, followUp])

        XCTAssertEqual(session.count, 1)
        XCTAssertEqual(session[0].reason.tier, 1)
    }

    func testNothingDueProducesAnEmptySession() {
        // Two thirds through a cadence, contacted recently, nothing captured.
        let quiet = person("Quiet", cadence: 30, lastContacted: daysAgo(20))

        XCTAssertTrue(run([quiet]).isEmpty, "An empty stack is an honest answer")
    }

    // MARK: - Eligibility

    func testSnoozedAndArchivedPeopleAreExcluded() {
        let snoozed = person("Snoozed", lastContacted: daysAgo(300), snoozedUntil: daysAhead(5))
        let archived = person("Archived", lastContacted: daysAgo(300), archived: true)
        let active = person("Active", lastContacted: daysAgo(40))

        XCTAssertEqual(names(run([snoozed, archived, active])), ["Active"])
    }

    func testSnoozeExpiryReturnsAPersonToRotation() {
        let expired = person("Expired", lastContacted: daysAgo(300), snoozedUntil: daysAgo(1))

        XCTAssertEqual(names(run([expired])), ["Expired"])
    }

    // MARK: - Cadence

    func testApproachingCadenceIsPlacedAfterEveryoneOverdue() {
        let soft = person("Soft", cadence: 30, lastContacted: daysAgo(25))
        let barely = person("Barely", cadence: 30, lastContacted: daysAgo(31))
        let deeply = person("Deeply", cadence: 30, lastContacted: daysAgo(90))

        let session = run([soft, barely, deeply])

        XCTAssertEqual(names(session), ["Deeply", "Barely", "Soft"])
        XCTAssertEqual(session[2].reason, .approachingCadence(daysSinceContact: 25))
    }

    func testBelowTheSoftThresholdNobodySurfaces() {
        let notYet = person("NotYet", cadence: 30, lastContacted: daysAgo(20))

        XCTAssertTrue(run([notYet]).isEmpty)
    }

    func testNeverContactedCountsFromTheDayTheyWereAdded() {
        let justAdded = person("JustAdded", cadence: 30, lastContacted: nil, created: daysAgo(2))
        let addedLongAgo = person("AddedLongAgo", cadence: 30, lastContacted: nil, created: daysAgo(45))

        // Adding someone must not make them instantly overdue.
        XCTAssertEqual(names(run([justAdded, addedLongAgo])), ["AddedLongAgo"])
    }

    // MARK: - Dates

    func testOnlyDatesInsideTheHorizonSurface() {
        let soon = MonthDay(date: daysAhead(3), calendar: calendar)!
        let later = MonthDay(date: daysAhead(10), calendar: calendar)!
        let inside = person("Inside", cadence: 300, lastContacted: daysAgo(1), birthday: soon)
        let outside = person("Outside", cadence: 300, lastContacted: daysAgo(1), birthday: later)

        let session = run([inside, outside])

        XCTAssertEqual(names(session), ["Inside"])
        XCTAssertEqual(session[0].reason, .dateApproaching(
            label: "Birthday",
            on: calendar.startOfDay(for: daysAhead(3)),
            daysAway: 3
        ))
    }

    func testDatesOutrankCadence() {
        let birthday = MonthDay(date: daysAhead(1), calendar: calendar)!
        let celebrating = person("Celebrating", cadence: 300, lastContacted: daysAgo(1), birthday: birthday)
        let overdue = person("Overdue", cadence: 30, lastContacted: daysAgo(200))

        XCTAssertEqual(names(run([celebrating, overdue])), ["Celebrating", "Overdue"])
    }

    // MARK: - Serendipity

    func testSerendipityFillsAQuietStack() {
        // Long cadence, so no rule would ever surface them, but they have
        // genuinely drifted. This is the case the slot exists for.
        let dormant = person("Dormant", cadence: 365, lastContacted: daysAgo(100))

        let session = run([dormant])

        XCTAssertEqual(names(session), ["Dormant"])
        XCTAssertEqual(session[0].reason, .serendipity(daysSinceContact: 100))
    }

    func testSerendipityIsSkippedWhenTheSessionIsAlreadyFull() {
        let full = (0..<5).map { person("F\($0)", lastContacted: daysAgo(100 + $0)) }
        let dormant = person("Dormant", cadence: 365, lastContacted: daysAgo(100))

        let session = run(full + [dormant])

        XCTAssertEqual(session.count, 5)
        XCTAssertFalse(names(session).contains("Dormant"))
    }

    func testSerendipityIgnoresPeopleContactedRecently() {
        // The bug this guards against: with room in the stack and nobody
        // dormant, the slot used to surface whoever was left over, including
        // someone spoken to yesterday.
        let yesterday = person("Yesterday", cadence: 365, lastContacted: daysAgo(1))

        XCTAssertTrue(run([yesterday]).isEmpty)
    }

    func testSerendipityPrefersTheLongestOutOfTouch() {
        let people = (0..<12).map { person("D\($0)", cadence: 365, lastContacted: daysAgo(40 + $0 * 10)) }

        // Whatever the seed, the pick comes from the most dormant few.
        for seed in UInt64(1)...20 {
            let session = run(people, seed: seed)
            XCTAssertEqual(session.count, 1)
            XCTAssertTrue(
                ["D11", "D10", "D9", "D8", "D7"].contains(session[0].person.name),
                "Serendipity drew from outside the dormant pool: \(session[0].person.name)"
            )
        }
    }

    // MARK: - Tone

    func testCardLinesNeverCountDaysAtTheUser() {
        let phrases = [0, 1, 5, 10, 17, 30, 60, 100, 200, 500]
            .map { SurfaceReason.softTimePhrase(days: $0) }

        for phrase in phrases {
            XCTAssertFalse(phrase.contains("overdue"), "Guilt language in: \(phrase)")
            XCTAssertFalse(phrase.contains("!"), "Urgency punctuation in: \(phrase)")
            XCTAssertNil(
                phrase.rangeOfCharacter(from: CharacterSet.decimalDigits),
                "A raw day count leaked into: \(phrase)"
            )
        }
    }
}

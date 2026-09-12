import Foundation

/// How much the user wants to invest in a relationship.
///
/// Intent nudges the starting cadence and nothing else. It is deliberately not
/// a score, a grade, or an input to any judgment about the relationship.
enum RelationshipIntent: String, Codable, CaseIterable, Identifiable {
    case invest
    case maintain
    case keepWarm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .invest: return "Invest"
        case .maintain: return "Maintain"
        case .keepWarm: return "Keep warm"
        }
    }

    var blurb: String {
        switch self {
        case .invest: return "People I want to be actively close to"
        case .maintain: return "People I want to stay in regular touch with"
        case .keepWarm: return "People I do not want to lose track of"
        }
    }

    /// Starting cadence only. The user can change it per person at any time.
    var suggestedCadenceDays: Int {
        switch self {
        case .invest: return 7
        case .maintain: return 30
        case .keepWarm: return 90
        }
    }
}

/// A recurring calendar day with no year, for birthdays and anniversaries.
struct MonthDay: Codable, Equatable, Hashable {
    var month: Int
    var day: Int

    init(month: Int, day: Int) {
        self.month = month
        self.day = day
    }

    init?(date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.month, .day], from: date)
        guard let month = parts.month, let day = parts.day else { return nil }
        self.init(month: month, day: day)
    }

    /// The next time this day comes around, counting today as "next".
    func nextOccurrence(onOrAfter now: Date, calendar: Calendar = .current) -> Date? {
        let today = calendar.startOfDay(for: now)
        let year = calendar.component(.year, from: today)
        var components = DateComponents()
        components.month = month
        components.day = day

        for candidateYear in [year, year + 1] {
            components.year = candidateYear
            if let date = calendar.date(from: components), date >= today {
                return date
            }
        }
        return nil
    }
}

struct ImportantDate: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var label: String
    var monthDay: MonthDay

    init(id: UUID = UUID(), label: String, monthDay: MonthDay) {
        self.id = id
        self.label = label
        self.monthDay = monthDay
    }
}

/// Someone the user is keeping track of.
struct Person: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var intent: RelationshipIntent
    var cadenceDays: Int
    var phoneNumber: String? = nil
    var birthday: MonthDay? = nil
    var importantDates: [ImportantDate] = []
    var notes: String = ""
    var lastContactedAt: Date? = nil
    var snoozedUntil: Date? = nil
    /// How many times this person has been snoozed. Used only to mention it
    /// gently on the card. It is never shown as a failure.
    var snoozeCount: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String,
        intent: RelationshipIntent,
        cadenceDays: Int? = nil,
        phoneNumber: String? = nil,
        birthday: MonthDay? = nil,
        importantDates: [ImportantDate] = [],
        notes: String = "",
        lastContactedAt: Date? = nil,
        snoozedUntil: Date? = nil,
        snoozeCount: Int = 0,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.intent = intent
        self.cadenceDays = cadenceDays ?? intent.suggestedCadenceDays
        self.phoneNumber = phoneNumber
        self.birthday = birthday
        self.importantDates = importantDates
        self.notes = notes
        self.lastContactedAt = lastContactedAt
        self.snoozedUntil = snoozedUntil
        self.snoozeCount = snoozeCount
        self.isArchived = isArchived
        self.createdAt = createdAt
    }

    /// Tolerant decoding so that adding a field later does not make older
    /// saved data unreadable.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        intent = try container.decodeIfPresent(RelationshipIntent.self, forKey: .intent) ?? .maintain
        let decodedCadence = try container.decodeIfPresent(Int.self, forKey: .cadenceDays)
        cadenceDays = decodedCadence ?? intent.suggestedCadenceDays
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        birthday = try container.decodeIfPresent(MonthDay.self, forKey: .birthday)
        importantDates = try container.decodeIfPresent([ImportantDate].self, forKey: .importantDates) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        lastContactedAt = try container.decodeIfPresent(Date.self, forKey: .lastContactedAt)
        snoozedUntil = try container.decodeIfPresent(Date.self, forKey: .snoozedUntil)
        snoozeCount = try container.decodeIfPresent(Int.self, forKey: .snoozeCount) ?? 0
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func isSnoozed(at now: Date) -> Bool {
        guard let snoozedUntil else { return false }
        return snoozedUntil > now
    }

    /// A person is in the rotation unless they are archived or snoozed.
    func isEligibleToSurface(at now: Date) -> Bool {
        !isArchived && !isSnoozed(at: now)
    }

    /// The clock the cadence runs from. Someone never contacted counts from
    /// the day they were added, so adding a person does not instantly make
    /// them overdue.
    var cadenceBaseline: Date {
        lastContactedAt ?? createdAt
    }

    func daysSinceContact(at now: Date, calendar: Calendar = .current) -> Int {
        let from = calendar.startOfDay(for: cadenceBaseline)
        let to = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// All recurring dates worth surfacing, birthday included.
    var allImportantDates: [ImportantDate] {
        var dates: [ImportantDate] = []
        if let birthday {
            dates.append(ImportantDate(id: id, label: "Birthday", monthDay: birthday))
        }
        dates.append(contentsOf: importantDates)
        return dates
    }
}

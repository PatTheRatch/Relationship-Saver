import Foundation

/// The kinds of thing the user can capture in a few seconds.
///
/// `replyOwed` is the manual baseline for the reply queue. iOS gives third
/// party apps no way to see unread or unanswered messages, so the user tells
/// the app instead. Anything captured this way sorts ahead of everything else.
enum CaptureKind: String, Codable, CaseIterable, Identifiable {
    case replyOwed
    case followUp
    case reachOut
    case note
    case importantDate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .replyOwed: return "I owe a reply"
        case .followUp: return "Follow up"
        case .reachOut: return "Reach out later"
        case .note: return "Note about them"
        case .importantDate: return "Important date"
        }
    }

    var symbolName: String {
        switch self {
        case .replyOwed: return "arrowshape.turn.up.left"
        case .followUp: return "clock.arrow.circlepath"
        case .reachOut: return "hand.wave"
        case .note: return "note.text"
        case .importantDate: return "calendar"
        }
    }

    /// Whether this kind is expected to carry a due date.
    var usesDueDate: Bool {
        self == .followUp
    }
}

/// A thought captured before it disappears.
struct Capture: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    /// Captures can exist without a person attached. Those wait in the inbox
    /// until the user assigns them, rather than being lost.
    var personID: UUID? = nil
    var text: String
    var kind: CaptureKind
    var dueAt: Date? = nil
    var createdAt: Date = Date()
    var completedAt: Date? = nil

    init(
        id: UUID = UUID(),
        personID: UUID? = nil,
        text: String,
        kind: CaptureKind,
        dueAt: Date? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.personID = personID
        self.text = text
        self.kind = kind
        self.dueAt = dueAt
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        personID = try container.decodeIfPresent(UUID.self, forKey: .personID)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        kind = try container.decodeIfPresent(CaptureKind.self, forKey: .kind) ?? .note
        dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }

    var isOpen: Bool { completedAt == nil }

    func isDue(at now: Date) -> Bool {
        guard let dueAt else { return false }
        return dueAt <= now
    }
}

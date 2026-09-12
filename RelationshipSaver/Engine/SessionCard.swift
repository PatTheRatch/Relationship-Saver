import Foundation

/// Why a person came back into attention.
///
/// The order of these cases is the priority order of the session. Replies
/// always come before initiations, because an unanswered message is the
/// failure mode that does the most relationship damage.
enum SurfaceReason: Equatable {
    /// The user told the app they owe this person a reply.
    case replyOwed(captureID: UUID, note: String, since: Date)
    /// A captured follow up has come due.
    case followUpDue(captureID: UUID, note: String, dueAt: Date)
    /// A birthday or important date is coming up.
    case dateApproaching(label: String, on: Date, daysAway: Int)
    /// Past their contact cadence.
    case pastCadence(daysSinceContact: Int)
    /// Approaching their cadence but not past it. These only appear when the
    /// stack is otherwise quiet, so contact feels spontaneous rather than
    /// triggered by a deadline.
    case approachingCadence(daysSinceContact: Int)
    /// The one slot reserved for someone the rules would never have picked.
    case serendipity(daysSinceContact: Int)

    /// Lower tiers are surfaced first.
    var tier: Int {
        switch self {
        case .replyOwed: return 1
        case .followUpDue: return 2
        case .dateApproaching: return 3
        case .pastCadence, .approachingCadence: return 4
        case .serendipity: return 5
        }
    }

    /// Distinguishes replying from initiating, for stats and for copy.
    var isReply: Bool {
        if case .replyOwed = self { return true }
        return false
    }

    /// The line shown on the card.
    ///
    /// Tone rules apply here: no counts of days overdue, no red, no language
    /// that implies the user has failed at anything.
    var cardLine: String {
        switch self {
        case .replyOwed(_, let note, _):
            return note.isEmpty ? "You wanted to get back to them" : note
        case .followUpDue(_, let note, _):
            return note.isEmpty ? "You wanted to follow up" : note
        case .dateApproaching(let label, _, let daysAway):
            switch daysAway {
            case 0: return "\(label) is today"
            case 1: return "\(label) is tomorrow"
            default: return "\(label) is in \(daysAway) days"
            }
        case .pastCadence(let days), .approachingCadence(let days), .serendipity(let days):
            return Self.softTimePhrase(days: days)
        }
    }

    /// Deliberately vague. "About a month" reads as a gentle observation.
    /// "31 days overdue" reads as an accusation.
    static func softTimePhrase(days: Int) -> String {
        switch days {
        case ..<0: return "It has been a little while"
        case 0: return "You were in touch today"
        case 1: return "You were in touch yesterday"
        case 2...6: return "It has been a few days"
        case 7...13: return "It has been about a week"
        case 14...20: return "It has been a couple of weeks"
        case 21...34: return "It has been about a month"
        case 35...75: return "It has been a couple of months"
        case 76...135: return "It has been a few months"
        case 136...300: return "It has been a long while"
        default: return "It has been over a year"
        }
    }
}

/// One person, one reason, one card.
struct SessionCard: Identifiable, Equatable {
    var person: Person
    var reason: SurfaceReason

    var id: UUID { person.id }
}

import Foundation

/// A fixed, small set. There is no date picker in the primary flow, because
/// every extra decision is another chance for the user to disengage.
enum SnoozeDuration: String, CaseIterable, Identifiable {
    case fewDays
    case nextWeek
    case nextMonth
    case aWhile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fewDays: return "A few days"
        case .nextWeek: return "Next week"
        case .nextMonth: return "Next month"
        case .aWhile: return "Not for a while"
        }
    }

    var days: Int {
        switch self {
        case .fewDays: return 3
        case .nextWeek: return 7
        case .nextMonth: return 30
        case .aWhile: return 90
        }
    }

    /// `aWhile` is the pause case from the north star. It is the same
    /// mechanism with a longer duration, which is all pause ever needed to be.
    var isPause: Bool { self == .aWhile }

    func until(from now: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: now) ?? now.addingTimeInterval(Double(days) * 86_400)
    }
}

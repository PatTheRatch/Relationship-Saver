import Foundation

/// Append only analytics, written from the first day, with no UI in V1.
///
/// This exists so the north star metric can be answered later. It is cheap to
/// write now and impossible to reconstruct after the fact. Events are never
/// deleted, including when a person is archived.
enum EventType: String, Codable {
    case personAdded
    case captureCreated
    case captureCompleted
    case personSurfaced
    case actionTaken
    case sessionStarted
    case sessionCompleted
    case notificationScheduled
    case notificationOpened
}

/// The action the user took on a card.
enum CardAction: String, Codable {
    case message
    case markedConnected
    case snoozed
    case archived
    case skipped
}

struct Event: Identifiable, Codable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var type: EventType
    var personID: UUID? = nil
    var sessionID: UUID? = nil
    /// Small, flat, string only. Keeps the log trivially readable and keeps
    /// encoding from ever being the reason an event fails to be written.
    var payload: [String: String] = [:]

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: EventType,
        personID: UUID? = nil,
        sessionID: UUID? = nil,
        payload: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.personID = personID
        self.sessionID = sessionID
        self.payload = payload
    }
}

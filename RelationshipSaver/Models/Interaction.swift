import Foundation

/// How an interaction was recorded.
enum InteractionChannel: String, Codable {
    /// The user composed a message from inside the app.
    case message
    /// The user tapped "We connected" for something that happened elsewhere.
    case markedConnected
}

/// A recorded contact with someone. Resets the relationship clock.
///
/// The app deliberately does not ask which app or medium was used. Requiring
/// the user to categorise the interaction is friction with no payoff.
struct Interaction: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var personID: UUID
    var at: Date
    var channel: InteractionChannel
    /// True when this interaction started from a resurfaced card. This is the
    /// flag the north star metric is built on: it distinguishes contact the
    /// app caused from contact that would have happened anyway.
    var promptedByApp: Bool

    init(
        id: UUID = UUID(),
        personID: UUID,
        at: Date = Date(),
        channel: InteractionChannel,
        promptedByApp: Bool
    ) {
        self.id = id
        self.personID = personID
        self.at = at
        self.channel = channel
        self.promptedByApp = promptedByApp
    }
}

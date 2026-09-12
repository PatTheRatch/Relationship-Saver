import Foundation

/// Append only event log, written as JSON Lines.
///
/// One event per line means a truncated write can only ever cost the last
/// event, never the file. Nothing here is ever deleted or rewritten, including
/// when a person is archived, because the whole point is to be able to answer
/// the north star question a year from now.
final class EventLog: @unchecked Sendable {

    private let url: URL
    private let queue = DispatchQueue(label: "com.relationshipsaver.eventlog", qos: .utility)
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init(url: URL) {
        self.url = url
    }

    func record(_ event: Event) {
        queue.async { [url, encoder] in
            guard var line = try? encoder.encode(event) else { return }
            line.append(0x0A) // newline

            let manager = FileManager.default
            if !manager.fileExists(atPath: url.path) {
                try? manager.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                manager.createFile(atPath: url.path, contents: nil)
            }

            guard let handle = try? FileHandle(forWritingTo: url) else { return }
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: line)
        }
    }

    func record(
        _ type: EventType,
        personID: UUID? = nil,
        sessionID: UUID? = nil,
        payload: [String: String] = [:]
    ) {
        record(Event(type: type, personID: personID, sessionID: sessionID, payload: payload))
    }

    /// Reads the whole log back. Unused by the app in V1, but the reason the
    /// log exists, and useful from a debugger or a future stats screen.
    func allEvents() -> [Event] {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return text
            .split(separator: "\n")
            .compactMap { line in
                guard let lineData = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(Event.self, from: lineData)
            }
    }
}

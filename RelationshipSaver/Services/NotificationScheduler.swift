import Foundation
import UserNotifications

/// The daily nudge.
///
/// One notification per day, at a time the user picks, and nothing else.
/// The copy describes the session rather than the backlog, and never carries
/// a count, because a growing number is the thing that turns a calm tool into
/// a source of dread. If the user ignores it, tomorrow's is identical. The app
/// does not escalate.
enum NotificationScheduler {

    static let dailyNudgeIdentifier = "daily-nudge"

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func scheduleDailyNudge(hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyNudgeIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "A few people to catch up on"
        content.body = "Whenever you have a minute."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let request = UNNotificationRequest(
            identifier: dailyNudgeIdentifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )

        try? await center.add(request)
    }

    static func cancelDailyNudge() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyNudgeIdentifier])
    }
}

import SwiftUI
import UserNotifications

struct SettingsView: View {

    @Environment(Store.self) private var store
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section("Daily nudge") {
                    Toggle("Bring me a few people each day", isOn: $store.settings.dailyNudgeEnabled)

                    if store.settings.dailyNudgeEnabled {
                        DatePicker(
                            "Time",
                            selection: nudgeTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                    }

                    Text("One notification a day. Never a count, never a reminder that you are behind.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if authorizationStatus == .denied {
                    Section {
                        Text("Notifications are turned off for this app in iOS Settings. The stack still works, but nothing will bring you back to it.")
                            .font(.caption)
                    }
                }

                Section("Session") {
                    LabeledContent("Cards per session", value: "5")
                    LabeledContent("People tracked", value: String(store.activePeople.count))
                }
            }
            .navigationTitle("Settings")
            .task {
                authorizationStatus = await NotificationScheduler.authorizationStatus()
                if authorizationStatus == .notDetermined, store.settings.dailyNudgeEnabled {
                    _ = await NotificationScheduler.requestAuthorization()
                    authorizationStatus = await NotificationScheduler.authorizationStatus()
                }
            }
            .onChange(of: store.settings) { _, _ in
                Task { await store.applyNotificationSettings() }
            }
        }
    }

    private var nudgeTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = store.settings.dailyNudgeHour
                components.minute = store.settings.dailyNudgeMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                store.settings.dailyNudgeHour = parts.hour ?? 18
                store.settings.dailyNudgeMinute = parts.minute ?? 30
            }
        )
    }
}

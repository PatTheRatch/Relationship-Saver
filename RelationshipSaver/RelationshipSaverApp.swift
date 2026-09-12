import SwiftUI

@main
struct RelationshipSaverApp: App {

    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task {
                    await store.applyNotificationSettings()
                }
        }
    }
}

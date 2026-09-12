import SwiftUI

struct RootView: View {

    @Environment(Store.self) private var store

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.horizon") }

            PeopleView()
                .tabItem { Label("People", systemImage: "person.2") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

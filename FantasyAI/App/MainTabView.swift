import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            RosterView()
                .tabItem { Label("Roster", systemImage: "person.3.fill") }
            RecommendationsView()
                .tabItem { Label("Advice", systemImage: "sparkles") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

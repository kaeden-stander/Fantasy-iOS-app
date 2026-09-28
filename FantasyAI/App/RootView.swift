import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authManager: ESPNAuthManager
    @EnvironmentObject private var leagueStore: LeagueStore

    var body: some View {
        if authManager.isAuthenticated, !leagueStore.savedLeagues.isEmpty {
            MainTabView()
        } else {
            LeagueSetupView()
        }
    }
}

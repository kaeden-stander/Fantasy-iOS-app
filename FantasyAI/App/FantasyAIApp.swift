import SwiftUI

@main
struct FantasyAIApp: App {
    @StateObject private var authManager: ESPNAuthManager
    @StateObject private var leagueStore: LeagueStore
    @StateObject private var secureConfig: SecureConfig
    @StateObject private var appState: AppState

    init() {
        let authManager = ESPNAuthManager()
        let leagueStore = LeagueStore()
        let secureConfig = SecureConfig()
        _authManager = StateObject(wrappedValue: authManager)
        _leagueStore = StateObject(wrappedValue: leagueStore)
        _secureConfig = StateObject(wrappedValue: secureConfig)
        _appState = StateObject(wrappedValue: AppState(authManager: authManager, leagueStore: leagueStore, secureConfig: secureConfig))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authManager)
                .environmentObject(leagueStore)
                .environmentObject(secureConfig)
        }
    }
}

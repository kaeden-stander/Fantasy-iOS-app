import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: ESPNAuthManager
    @EnvironmentObject private var leagueStore: LeagueStore
    @EnvironmentObject private var secureConfig: SecureConfig
    @State private var apiKeyInput: String = ""
    @State private var showingAddLeague = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Anthropic API Key") {
                    SecureField("sk-ant-...", text: $apiKeyInput)
                    Button("Save Key") {
                        secureConfig.saveAPIKey(apiKeyInput)
                        apiKeyInput = ""
                    }
                    .disabled(apiKeyInput.isEmpty)
                    if secureConfig.anthropicAPIKey != nil {
                        Label("Key saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section("Leagues") {
                    ForEach(leagueStore.savedLeagues) { league in
                        Button {
                            Task { await appState.switchLeague(to: league) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(league.displayName)
                                    Text(league.sport.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if appState.activeSavedLeague?.id == league.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            leagueStore.remove(leagueStore.savedLeagues[index])
                        }
                    }
                    Button("Add Another League") { showingAddLeague = true }
                }

                Section("ESPN Account") {
                    Button("Log out of ESPN", role: .destructive) {
                        authManager.signOut()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddLeague) {
                LeagueSetupView()
            }
        }
    }
}

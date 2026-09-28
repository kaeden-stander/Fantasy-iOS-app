import SwiftUI

struct LeagueSetupView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: ESPNAuthManager
    @EnvironmentObject private var leagueStore: LeagueStore
    @StateObject private var viewModel = LeagueSetupViewModel()
    @State private var showingAuthSheet = false
    @State private var selectedTeamId: Int?

    var body: some View {
        NavigationStack {
            Form {
                if !authManager.isAuthenticated {
                    Section {
                        Text("Log in to ESPN to load your fantasy leagues. Your password never touches this app or Claude — only ESPN sees it.")
                            .foregroundStyle(.secondary)
                        Button("Log in to ESPN") { showingAuthSheet = true }
                    }
                } else {
                    Section("League") {
                        Picker("Sport", selection: $viewModel.sport) {
                            ForEach(Sport.allCases) { sport in
                                Text(sport.displayName).tag(sport)
                            }
                        }
                        TextField("League ID", text: $viewModel.leagueIdText)
                            .keyboardType(.numberPad)
                        Stepper("Season \(viewModel.seasonYear)", value: $viewModel.seasonYear, in: 2018...2100)
                        Button {
                            Task { await viewModel.fetchLeague(using: appState.espnClient) }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Find League")
                            }
                        }
                        .disabled(viewModel.isLoading || viewModel.leagueIdText.isEmpty)
                    }

                    if let error = viewModel.errorMessage {
                        Section {
                            Text(error).foregroundStyle(.red)
                        }
                    }

                    if let league = viewModel.fetchedLeague {
                        Section("Which team is yours?") {
                            Picker("My team", selection: $selectedTeamId) {
                                Text("Choose a team").tag(Int?.none)
                                ForEach(league.teams) { team in
                                    Text(team.name).tag(Optional(team.id))
                                }
                            }
                            Button("Save League") {
                                saveLeague(league)
                            }
                            .disabled(selectedTeamId == nil)
                        }
                    }
                }
            }
            .navigationTitle("Add a League")
            .sheet(isPresented: $showingAuthSheet) {
                ESPNAuthWebView { credentials in
                    authManager.save(credentials)
                    showingAuthSheet = false
                }
            }
        }
    }

    private func saveLeague(_ league: League) {
        guard let teamId = selectedTeamId else { return }
        let saved = SavedLeague(
            leagueId: league.id,
            sport: league.sport,
            seasonYear: league.seasonYear,
            displayName: league.name,
            myTeamId: teamId
        )
        leagueStore.add(saved)
        Task { await appState.switchLeague(to: saved) }
    }
}

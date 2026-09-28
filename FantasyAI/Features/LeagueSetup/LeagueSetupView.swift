import SwiftUI
import UIKit

struct LeagueSetupView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: ESPNAuthManager
    @EnvironmentObject private var leagueStore: LeagueStore
    @StateObject private var viewModel = LeagueSetupViewModel()
    @State private var showingAuthSheet = false
    @State private var showingManualEntry = false
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
                    Section {
                        Text("If the web login gets stuck on ESPN's homepage instead of showing a sign-in form, use this instead.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Enter ESPN cookies manually") { showingManualEntry = true }
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
                            Task {
                                selectedTeamId = nil
                                await viewModel.fetchLeague(using: appState.espnClient)
                                selectedTeamId = matchedTeamId(in: viewModel.fetchedLeague)
                            }
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
                            Text(error)
                                .foregroundStyle(.red)
                                .textSelection(.enabled)
                            Button("Copy Error to Clipboard") {
                                UIPasteboard.general.string = error
                            }
                        }
                    }

                    if let league = viewModel.fetchedLeague {
                        Section("Which team is yours?") {
                            if matchedTeamId(in: league) != nil {
                                Text("Matched to your ESPN account. Change it below if that's wrong.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Couldn't match a team to your ESPN account automatically — pick yours.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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
            .sheet(isPresented: $showingManualEntry) {
                ManualCookieEntryView()
            }
        }
    }

    /// Finds the team whose owners include the signed-in user's ESPN member GUID (the
    /// SWID cookie value), so people don't have to guess which numbered team is theirs.
    private func matchedTeamId(in league: League?) -> Int? {
        guard let league, let swid = authManager.credentials?.swid else { return nil }
        return league.teams.first { team in
            team.ownerGUIDs.contains { $0.caseInsensitiveCompare(swid) == .orderedSame }
        }?.id
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

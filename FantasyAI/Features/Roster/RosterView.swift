import SwiftUI

struct RosterView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(appState.currentLeague?.name ?? "Roster")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(appState.isLoadingLeague)
                    }
                }
        }
        .task { await appState.bootstrapIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if appState.isLoadingLeague {
            ProgressView("Loading league…")
        } else if let error = appState.loadError {
            ContentUnavailableView(
                "Couldn't load league",
                systemImage: "wifi.slash",
                description: Text(error)
            )
        } else if let team = appState.myTeam {
            List {
                Section("Starters") {
                    ForEach(team.roster?.starters ?? []) { slot in
                        PlayerRow(slot: slot)
                    }
                }
                Section("Bench") {
                    ForEach(team.roster?.bench ?? []) { slot in
                        PlayerRow(slot: slot)
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "No team selected",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("Add a league in Settings and choose which team is yours.")
            )
        }
    }

    private func refresh() async {
        guard let saved = appState.activeSavedLeague else { return }
        await appState.loadLeague(saved)
    }
}

private struct PlayerRow: View {
    let slot: RosterSlot

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(slot.player.fullName).font(.headline)
                Text("\(slot.player.primaryPosition) · \(slot.player.proTeamAbbreviation)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.1f", slot.player.projectedPoints))
                    .font(.headline)
                if slot.player.injuryStatus != .active {
                    Text(slot.player.injuryStatus.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

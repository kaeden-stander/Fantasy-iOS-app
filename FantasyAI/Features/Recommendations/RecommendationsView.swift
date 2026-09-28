import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = RecommendationsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Asking Claude…")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Couldn't get advice",
                        systemImage: "sparkles",
                        description: Text(error)
                    )
                } else if viewModel.recommendations.isEmpty {
                    ContentUnavailableView(
                        "No advice yet",
                        systemImage: "sparkles",
                        description: Text("Tap the button below to get start/sit advice for your team.")
                    )
                } else {
                    List(viewModel.recommendations) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }
            }
            .navigationTitle("Advice")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Get Weekly Advice") {
                        Task { await requestAdvice() }
                    }
                    .disabled(appState.myTeam == nil || viewModel.isLoading)
                }
            }
        }
    }

    private func requestAdvice() async {
        guard let team = appState.myTeam, let sport = appState.currentLeague?.sport else { return }
        await viewModel.loadStartSitAdvice(
            team: team,
            opponent: appState.currentOpponent,
            sport: sport,
            engine: appState.recommendationEngine
        )
    }
}

private struct RecommendationCard: View {
    let recommendation: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recommendation.headline).font(.headline)
            Text(recommendation.reasoning)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(recommendation.suggestedActions, id: \.self) { action in
                Label(action, systemImage: "arrow.right")
                    .font(.caption)
            }
            ProgressView(value: recommendation.confidence)
                .tint(.accentColor)
        }
        .padding(.vertical, 4)
    }
}

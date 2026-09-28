import Foundation

@MainActor
final class RecommendationsViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadStartSitAdvice(team: Team, opponent: Team?, sport: Sport, engine: RecommendationEngine) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let results = try await engine.startSitRecommendations(for: team, opponent: opponent, sport: sport)
            recommendations = results
            if results.isEmpty {
                errorMessage = "Claude didn't return any recommendations. Try again in a moment."
            }
        } catch let error as ClaudeClient.ClaudeClientError {
            switch error {
            case .missingAPIKey:
                errorMessage = "Add your Anthropic API key in Settings first."
            default:
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var currentLeague: League?
    @Published var activeSavedLeague: SavedLeague?
    @Published var isLoadingLeague = false
    @Published var loadError: String?

    let authManager: ESPNAuthManager
    let leagueStore: LeagueStore
    let secureConfig: SecureConfig
    let espnClient: ESPNClient
    let recommendationEngine: RecommendationEngine

    init(authManager: ESPNAuthManager, leagueStore: LeagueStore, secureConfig: SecureConfig) {
        self.authManager = authManager
        self.leagueStore = leagueStore
        self.secureConfig = secureConfig
        self.espnClient = ESPNClient(credentialsProvider: { authManager.credentials })
        let claudeClient = ClaudeClient(apiKeyProvider: { secureConfig.anthropicAPIKey })
        self.recommendationEngine = RecommendationEngine(claudeClient: claudeClient)
    }

    /// Loads the first saved league on first appearance, if one hasn't been loaded yet.
    func bootstrapIfNeeded() async {
        if activeSavedLeague == nil {
            activeSavedLeague = leagueStore.savedLeagues.first
        }
        guard let activeSavedLeague, currentLeague == nil else { return }
        await loadLeague(activeSavedLeague)
    }

    func switchLeague(to saved: SavedLeague) async {
        activeSavedLeague = saved
        await loadLeague(saved)
    }

    func loadLeague(_ saved: SavedLeague) async {
        isLoadingLeague = true
        loadError = nil
        defer { isLoadingLeague = false }
        do {
            currentLeague = try await espnClient.fetchLeague(sport: saved.sport, seasonYear: saved.seasonYear, leagueId: saved.leagueId)
        } catch {
            loadError = error.localizedDescription
        }
    }

    var myTeam: Team? {
        guard let league = currentLeague, let myTeamId = activeSavedLeague?.myTeamId else { return nil }
        return league.teams.first { $0.id == myTeamId }
    }

    var currentOpponent: Team? {
        guard let league = currentLeague, let myTeam else { return nil }
        guard let matchup = league.matchups.first(where: {
            $0.week == league.currentScoringPeriod && ($0.homeTeamId == myTeam.id || $0.awayTeamId == myTeam.id)
        }) else { return nil }
        let opponentId = matchup.homeTeamId == myTeam.id ? matchup.awayTeamId : matchup.homeTeamId
        return league.teams.first { $0.id == opponentId }
    }
}

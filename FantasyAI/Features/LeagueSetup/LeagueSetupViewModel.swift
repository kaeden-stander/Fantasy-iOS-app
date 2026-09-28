import Foundation

@MainActor
final class LeagueSetupViewModel: ObservableObject {
    @Published var sport: Sport = .football
    @Published var leagueIdText: String = ""
    @Published var seasonYear: Int = Calendar.current.component(.year, from: Date())
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var fetchedLeague: League?

    func fetchLeague(using espnClient: ESPNClient) async {
        guard let leagueId = Int(leagueIdText) else {
            errorMessage = "Enter a numeric league ID. You can find it in the URL when you view your league on espn.com."
            return
        }
        isLoading = true
        errorMessage = nil
        fetchedLeague = nil
        defer { isLoading = false }
        do {
            fetchedLeague = try await espnClient.fetchLeague(sport: sport, seasonYear: seasonYear, leagueId: leagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

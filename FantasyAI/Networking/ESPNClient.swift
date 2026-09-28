import Foundation

enum ESPNClientError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "ESPN returned an unexpected response."
        case .httpError(let code):
            return "ESPN returned HTTP \(code). If this is a private league, make sure you're logged in with an account that's a member of it."
        case .decodingFailed:
            return "ESPN's response didn't match what this app expected. ESPN's fantasy API is unofficial and can change without notice."
        }
    }
}

/// Talks to ESPN's unofficial fantasy sports API. Private leagues require the SWID and
/// espn_s2 cookies from a logged-in ESPN session (see ESPNAuthManager); public leagues
/// work without them.
final class ESPNClient {
    private let session: URLSession
    private let credentialsProvider: () -> ESPNCredentials?

    init(session: URLSession = .shared, credentialsProvider: @escaping () -> ESPNCredentials?) {
        self.session = session
        self.credentialsProvider = credentialsProvider
    }

    func fetchLeague(sport: Sport, seasonYear: Int, leagueId: Int) async throws -> League {
        let url = ESPNEndpoints.leagueURL(
            sport: sport,
            seasonYear: seasonYear,
            leagueId: leagueId,
            views: ["mTeam", "mRoster", "mMatchup", "mSettings"]
        )

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let credentials = credentialsProvider() {
            request.setValue("SWID=\(credentials.swid); espn_s2=\(credentials.espnS2)", forHTTPHeaderField: "Cookie")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ESPNClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ESPNClientError.httpError(httpResponse.statusCode)
        }

        do {
            let dto = try JSONDecoder().decode(ESPNLeagueDTO.self, from: data)
            return ESPNMapper.map(dto: dto, sport: sport, seasonYear: seasonYear)
        } catch {
            throw ESPNClientError.decodingFailed(error)
        }
    }
}

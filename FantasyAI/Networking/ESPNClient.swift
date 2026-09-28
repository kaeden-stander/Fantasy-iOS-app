import Foundation

enum ESPNClientError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case redirected(status: Int, location: String?)
    case leagueNotFound
    case decodingFailed(Error, responseSnippet: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "ESPN returned an unexpected response."
        case .httpError(let code):
            return "ESPN returned HTTP \(code). If this is a private league, make sure the cookies are from an account that's a member of it, and that they haven't expired."
        case .redirected(let status, let location):
            return "ESPN redirected this request (HTTP \(status)) instead of answering it directly"
                + (location.map { " — to: \($0)" } ?? "")
                + ". That usually means this API path has moved or been retired."
        case .leagueNotFound:
            return "ESPN says this league doesn't exist for that sport and season. Double-check the league ID, the sport, and the season year — the league ID is the number after \"leagueId=\" when you view your league on espn.com."
        case .decodingFailed(_, let snippet):
            return "ESPN's response didn't match what this app expected (its fantasy API is unofficial and can change). What ESPN actually sent back:\n\n\(snippet)"
        }
    }
}

/// Denies HTTP redirects instead of silently following them. ESPN's unofficial API can
/// redirect an old/moved path to a generic marketing page with an ordinary 200 status,
/// which would otherwise look just like a successful-but-wrong response. Blocking the
/// redirect surfaces it as what it actually is.
private final class RedirectBlockingDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

/// Talks to ESPN's unofficial fantasy sports API. Private leagues require the SWID and
/// espn_s2 cookies from a logged-in ESPN session (see ESPNAuthManager); public leagues
/// work without them.
final class ESPNClient {
    private let session: URLSession
    private let redirectDelegate: RedirectBlockingDelegate
    private let credentialsProvider: () -> ESPNCredentials?

    init(credentialsProvider: @escaping () -> ESPNCredentials?) {
        let delegate = RedirectBlockingDelegate()
        self.redirectDelegate = delegate
        self.session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
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
        // Without a browser-like User-Agent, ESPN's edge sometimes routes requests to its
        // generic Fantasy Games marketing page instead of the JSON API — this is the app's
        // default request identity otherwise (e.g. "FantasyAI/1 CFNetwork/... Darwin/...").
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        if let credentials = credentialsProvider() {
            request.setValue("SWID=\(credentials.swid); espn_s2=\(credentials.espnS2)", forHTTPHeaderField: "Cookie")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ESPNClientError.invalidResponse
        }

        if (300..<400).contains(httpResponse.statusCode) {
            let location = httpResponse.value(forHTTPHeaderField: "Location")
            throw ESPNClientError.redirected(status: httpResponse.statusCode, location: location)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ESPNClientError.httpError(httpResponse.statusCode)
        }

        // ESPN answers a league ID that doesn't exist for this sport/season with an empty
        // JSON array (HTTP 200) instead of an error status, so check for that before trying
        // to decode it as a league object.
        if let firstNonWhitespace = data.first(where: { $0 != 0x20 && $0 != 0x0A && $0 != 0x09 }),
           firstNonWhitespace == UInt8(ascii: "[") {
            throw ESPNClientError.leagueNotFound
        }

        do {
            let dto = try JSONDecoder().decode(ESPNLeagueDTO.self, from: data)
            return ESPNMapper.map(dto: dto, sport: sport, seasonYear: seasonYear)
        } catch {
            let snippet = String(data: data.prefix(4000), encoding: .utf8) ?? "(response wasn't text)"
            throw ESPNClientError.decodingFailed(error, responseSnippet: snippet)
        }
    }
}

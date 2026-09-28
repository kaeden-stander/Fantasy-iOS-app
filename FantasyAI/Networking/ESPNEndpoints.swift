import Foundation

/// URL builders for ESPN's unofficial fantasy sports API. There is no public documentation
/// for these endpoints; the shape used here matches what community projects (e.g. the
/// espn-api Python library) have reverse-engineered. ESPN can change it without notice —
/// as of testing this app, `fantasy.espn.com/apis/v3/...` now 302-redirects to the regular
/// Fantasy Games marketing page instead of answering. ESPN has previously moved fantasy
/// read traffic onto a dedicated `lm-api-reads.fantasy.espn.com` host, so that's the next
/// thing to try; if this host is also wrong, capture the real request from a browser's
/// network tab while viewing the league on fantasy.espn.com and use that host/path instead.
enum ESPNEndpoints {
    static func leagueURL(sport: Sport, seasonYear: Int, leagueId: Int, views: [String]) -> URL {
        var components = URLComponents(
            string: "https://lm-api-reads.fantasy.espn.com/apis/v3/games/\(sport.espnGameAbbreviation)/seasons/\(seasonYear)/segments/0/leagues/\(leagueId)"
        )!
        components.queryItems = views.map { URLQueryItem(name: "view", value: $0) }
        return components.url!
    }
}

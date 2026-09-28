import Foundation

/// URL builders for ESPN's unofficial fantasy sports API. There is no public documentation
/// for these endpoints; the shape used here matches what community projects (e.g. the
/// espn-api Python library) have reverse-engineered. ESPN can change it without notice.
enum ESPNEndpoints {
    static func leagueURL(sport: Sport, seasonYear: Int, leagueId: Int, views: [String]) -> URL {
        var components = URLComponents(
            string: "https://fantasy.espn.com/apis/v3/games/\(sport.espnGameAbbreviation)/seasons/\(seasonYear)/segments/0/leagues/\(leagueId)"
        )!
        components.queryItems = views.map { URLQueryItem(name: "view", value: $0) }
        return components.url!
    }
}

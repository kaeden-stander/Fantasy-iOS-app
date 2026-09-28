import Foundation

struct Matchup: Identifiable, Codable, Hashable {
    let id: Int
    let week: Int
    let homeTeamId: Int
    let awayTeamId: Int
    let homeScore: Double
    let awayScore: Double
}

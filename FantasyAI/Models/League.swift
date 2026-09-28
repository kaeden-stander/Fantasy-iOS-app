import Foundation

struct League: Identifiable, Codable {
    let id: Int
    let sport: Sport
    let seasonYear: Int
    let name: String
    let currentScoringPeriod: Int
    var teams: [Team]
    var matchups: [Matchup]
}

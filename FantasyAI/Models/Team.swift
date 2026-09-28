import Foundation

struct Team: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let ownerName: String
    let wins: Int
    let losses: Int
    let ties: Int
    let pointsFor: Double
    let pointsAgainst: Double
    var roster: Roster?
}

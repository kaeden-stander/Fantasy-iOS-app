import Foundation

struct Team: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let ownerName: String
    /// ESPN member GUIDs (the same format as the SWID cookie) for everyone who owns this
    /// team, used to auto-detect which team belongs to the signed-in user.
    let ownerGUIDs: [String]
    let wins: Int
    let losses: Int
    let ties: Int
    let pointsFor: Double
    let pointsAgainst: Double
    var roster: Roster?
}

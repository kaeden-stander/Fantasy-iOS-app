import Foundation

struct Player: Identifiable, Codable, Hashable {
    enum InjuryStatus: String, Codable, Hashable {
        case active = "ACTIVE"
        case questionable = "QUESTIONABLE"
        case doubtful = "DOUBTFUL"
        case out = "OUT"
        case injuryReserve = "INJURY_RESERVE"
        case unknown = "UNKNOWN"
    }

    let id: Int
    let fullName: String
    let proTeamAbbreviation: String
    let eligiblePositions: [String]
    let primaryPosition: String
    let injuryStatus: InjuryStatus
    let percentOwned: Double
    let percentStarted: Double
    let projectedPoints: Double
    let actualPoints: Double
    let seasonTotalPoints: Double
}

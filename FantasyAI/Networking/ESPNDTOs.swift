import Foundation

// Raw wire-format types mirroring ESPN's undocumented fantasy JSON response for the
// mTeam + mRoster + mMatchup + mSettings views. These are mapped into the app's own
// domain models (League, Team, Roster, Player, Matchup) by ESPNMapper — nothing outside
// the Networking layer should decode this shape directly.

struct ESPNLeagueDTO: Decodable {
    let id: Int
    let seasonId: Int
    let scoringPeriodId: Int
    let teams: [ESPNTeamDTO]
    let schedule: [ESPNMatchupDTO]?
    let settings: ESPNSettingsDTO?
}

struct ESPNSettingsDTO: Decodable {
    let name: String?
}

struct ESPNTeamDTO: Decodable {
    let id: Int
    let location: String?
    let nickname: String?
    let owners: [String]?
    let record: ESPNRecordDTO?
    let roster: ESPNRosterDTO?
}

struct ESPNRecordDTO: Decodable {
    let overall: ESPNOverallRecordDTO?
}

struct ESPNOverallRecordDTO: Decodable {
    let wins: Int
    let losses: Int
    let ties: Int
    let pointsFor: Double
    let pointsAgainst: Double
}

struct ESPNRosterDTO: Decodable {
    let entries: [ESPNRosterEntryDTO]
}

struct ESPNRosterEntryDTO: Decodable {
    let playerId: Int
    let lineupSlotId: Int
    let playerPoolEntry: ESPNPlayerPoolEntryDTO
}

struct ESPNPlayerPoolEntryDTO: Decodable {
    let player: ESPNPlayerDTO
}

struct ESPNPlayerDTO: Decodable {
    let id: Int
    let fullName: String
    let proTeamId: Int
    let defaultPositionId: Int
    let eligibleSlots: [Int]?
    let injuryStatus: String?
    let ownership: ESPNOwnershipDTO?
    let stats: [ESPNPlayerStatDTO]?
}

struct ESPNOwnershipDTO: Decodable {
    let percentOwned: Double?
    let percentStarted: Double?
}

struct ESPNPlayerStatDTO: Decodable {
    let scoringPeriodId: Int?
    /// 0 = actual result, 1 = ESPN's own projection.
    let statSourceId: Int
    let appliedTotal: Double?
}

struct ESPNMatchupDTO: Decodable {
    let matchupPeriodId: Int
    let home: ESPNMatchupTeamDTO?
    let away: ESPNMatchupTeamDTO?
}

struct ESPNMatchupTeamDTO: Decodable {
    let teamId: Int
    let totalPoints: Double?
}

import Foundation

struct TradeProposal: Identifiable, Codable {
    let id: UUID
    let proposingTeamId: Int
    let counterpartTeamId: Int
    let playersOffered: [Player]
    let playersRequested: [Player]

    init(id: UUID = UUID(), proposingTeamId: Int, counterpartTeamId: Int, playersOffered: [Player], playersRequested: [Player]) {
        self.id = id
        self.proposingTeamId = proposingTeamId
        self.counterpartTeamId = counterpartTeamId
        self.playersOffered = playersOffered
        self.playersRequested = playersRequested
    }
}

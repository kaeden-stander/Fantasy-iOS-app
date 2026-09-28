import Foundation

struct RosterSlot: Identifiable, Codable, Hashable {
    let player: Player
    let lineupSlot: String
    let isStarting: Bool

    var id: Int { player.id }
}

struct Roster: Codable, Hashable {
    let teamId: Int
    let slots: [RosterSlot]

    var starters: [RosterSlot] { slots.filter { $0.isStarting } }
    var bench: [RosterSlot] { slots.filter { !$0.isStarting } }
}

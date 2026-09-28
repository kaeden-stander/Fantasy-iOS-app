import Foundation

/// Maps ESPN's numeric position and lineup slot IDs to human-readable abbreviations.
///
/// The football tables are verified against widely-used community references (e.g. the
/// espn-api Python project) and are safe to rely on. The basketball, baseball, and hockey
/// tables are best-effort placeholders — ESPN's IDs are not consistently documented for
/// those sports. Before trusting them, fetch one real league response per sport and compare
/// `defaultPositionId` / `lineupSlotId` values against the player names ESPN returns, then
/// fill these tables in.
enum ESPNPositionMap {
    static func positionName(defaultPositionId: Int, sport: Sport) -> String {
        switch sport {
        case .football: return footballPositions[defaultPositionId] ?? "FLEX"
        case .basketball: return basketballPositions[defaultPositionId] ?? "UTIL"
        case .baseball: return baseballPositions[defaultPositionId] ?? "UTIL"
        case .hockey: return hockeyPositions[defaultPositionId] ?? "UTIL"
        }
    }

    static func lineupSlotName(slotId: Int, sport: Sport) -> String {
        switch sport {
        case .football: return footballSlots[slotId] ?? "BENCH"
        default: return slotId == benchSlotId ? "BENCH" : "STARTER"
        }
    }

    static func isBenchSlot(slotId: Int, sport: Sport) -> Bool {
        switch sport {
        case .football: return slotId == benchSlotId || slotId == injuryReserveSlotId
        default: return slotId == benchSlotId
        }
    }

    /// ESPN uses slot id 20 for the bench across every fantasy sport.
    private static let benchSlotId = 20
    /// Football's injured-reserve slot.
    private static let injuryReserveSlotId = 21

    // MARK: Player position (defaultPositionId)

    private static let footballPositions: [Int: String] = [
        1: "QB", 2: "RB", 3: "WR", 4: "TE", 5: "K", 16: "D/ST"
    ]

    // Placeholder — verify against a live league response.
    private static let basketballPositions: [Int: String] = [
        0: "PG", 1: "SG", 2: "SF", 3: "PF", 4: "C"
    ]

    // Placeholder — verify against a live league response.
    private static let baseballPositions: [Int: String] = [
        0: "C", 1: "1B", 2: "2B", 3: "3B", 4: "SS", 5: "OF", 13: "P"
    ]

    // Placeholder — verify against a live league response.
    private static let hockeyPositions: [Int: String] = [
        0: "C", 1: "LW", 2: "RW", 4: "D", 5: "G"
    ]

    // MARK: Roster lineup slot (lineupSlotId)

    private static let footballSlots: [Int: String] = [
        0: "QB", 2: "RB", 4: "WR", 6: "TE", 16: "D/ST", 17: "K",
        20: "BENCH", 21: "IR", 23: "FLEX"
    ]
}

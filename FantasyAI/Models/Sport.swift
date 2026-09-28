import Foundation

/// A fantasy sport ESPN runs a game for. Football is the most complete integration in this
/// scaffold; the others share the same pipeline but their ESPN position/team ID tables are
/// placeholders (see ESPNPositionMap and ESPNProTeamMap) and need to be filled in against a
/// real league response before they can be trusted.
enum Sport: String, CaseIterable, Identifiable, Codable, Hashable {
    case football
    case basketball
    case baseball
    case hockey

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .football: return "Football"
        case .basketball: return "Basketball"
        case .baseball: return "Baseball"
        case .hockey: return "Hockey"
        }
    }

    /// ESPN's internal game abbreviation, used as a path segment in fantasy API URLs.
    var espnGameAbbreviation: String {
        switch self {
        case .football: return "ffl"
        case .basketball: return "fba"
        case .baseball: return "flb"
        case .hockey: return "fhl"
        }
    }

    var systemImageName: String {
        switch self {
        case .football: return "football.fill"
        case .basketball: return "basketball.fill"
        case .baseball: return "baseball.fill"
        case .hockey: return "hockey.puck.fill"
        }
    }
}

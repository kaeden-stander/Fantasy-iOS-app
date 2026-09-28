import Foundation

/// A league the user has added, plus which team is theirs. Non-secret, so it's kept in
/// UserDefaults rather than the Keychain.
struct SavedLeague: Codable, Hashable, Identifiable {
    let leagueId: Int
    let sport: Sport
    let seasonYear: Int
    var displayName: String
    var myTeamId: Int?

    var id: String { "\(sport.rawValue)-\(leagueId)-\(seasonYear)" }
}

@MainActor
final class LeagueStore: ObservableObject {
    @Published private(set) var savedLeagues: [SavedLeague] = []

    private let defaultsKey = "fantasyai.savedLeagues"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.savedLeagues = Self.load(from: defaults, key: defaultsKey)
    }

    func add(_ league: SavedLeague) {
        savedLeagues.removeAll { $0.leagueId == league.leagueId && $0.sport == league.sport }
        savedLeagues.append(league)
        persist()
    }

    func remove(_ league: SavedLeague) {
        savedLeagues.removeAll { $0.leagueId == league.leagueId && $0.sport == league.sport }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(savedLeagues) else { return }
        defaults.set(data, forKey: defaultsKey)
    }

    private static func load(from defaults: UserDefaults, key: String) -> [SavedLeague] {
        guard
            let data = defaults.data(forKey: key),
            let leagues = try? JSONDecoder().decode([SavedLeague].self, from: data)
        else { return [] }
        return leagues
    }
}

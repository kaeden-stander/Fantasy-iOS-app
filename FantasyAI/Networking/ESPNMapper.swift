import Foundation

/// Converts raw ESPN DTOs into the app's domain models.
enum ESPNMapper {
    static func map(dto: ESPNLeagueDTO, sport: Sport, seasonYear: Int) -> League {
        let teams = dto.teams.map { mapTeam($0, sport: sport, scoringPeriodId: dto.scoringPeriodId) }
        let matchups = (dto.schedule ?? []).compactMap { mapMatchup($0) }
        let name = dto.settings?.name ?? "League \(dto.id)"
        return League(
            id: dto.id,
            sport: sport,
            seasonYear: seasonYear,
            name: name,
            currentScoringPeriod: dto.scoringPeriodId,
            teams: teams,
            matchups: matchups
        )
    }

    private static func mapTeam(_ dto: ESPNTeamDTO, sport: Sport, scoringPeriodId: Int) -> Team {
        let name = resolvedTeamName(dto)
        let record = dto.record?.overall
        let roster = dto.roster.map { rosterDTO in
            Roster(
                teamId: dto.id,
                slots: rosterDTO.entries.map { mapRosterEntry($0, sport: sport, scoringPeriodId: scoringPeriodId) }
            )
        }
        return Team(
            id: dto.id,
            name: name,
            ownerName: dto.owners?.first ?? "Unknown",
            ownerGUIDs: dto.owners ?? [],
            wins: record?.wins ?? 0,
            losses: record?.losses ?? 0,
            ties: record?.ties ?? 0,
            pointsFor: record?.pointsFor ?? 0,
            pointsAgainst: record?.pointsAgainst ?? 0,
            roster: roster
        )
    }

    /// ESPN used to split a team's name into separate "location" and "nickname" fields
    /// (e.g. "My" + "Team"); newer responses use a single "name" field instead. Prefer
    /// whichever one is actually populated.
    private static func resolvedTeamName(_ dto: ESPNTeamDTO) -> String {
        if let name = dto.name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return name
        }
        let joined = [dto.location, dto.nickname].compactMap { $0 }.joined(separator: " ")
        let trimmed = joined.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Team \(dto.id)" : trimmed
    }

    private static func mapRosterEntry(_ dto: ESPNRosterEntryDTO, sport: Sport, scoringPeriodId: Int) -> RosterSlot {
        let player = mapPlayer(dto.playerPoolEntry.player, sport: sport, scoringPeriodId: scoringPeriodId)
        let slotName = ESPNPositionMap.lineupSlotName(slotId: dto.lineupSlotId, sport: sport)
        let isBench = ESPNPositionMap.isBenchSlot(slotId: dto.lineupSlotId, sport: sport)
        return RosterSlot(player: player, lineupSlot: slotName, isStarting: !isBench)
    }

    private static func mapPlayer(_ dto: ESPNPlayerDTO, sport: Sport, scoringPeriodId: Int) -> Player {
        let stats = dto.stats ?? []
        let actual = stats.first { $0.statSourceId == 0 && $0.scoringPeriodId == scoringPeriodId }?.appliedTotal ?? 0
        let projected = stats.first { $0.statSourceId == 1 && $0.scoringPeriodId == scoringPeriodId }?.appliedTotal ?? 0
        let seasonTotal = stats
            .filter { $0.statSourceId == 0 }
            .reduce(0) { $0 + ($1.appliedTotal ?? 0) }
        let position = ESPNPositionMap.positionName(defaultPositionId: dto.defaultPositionId, sport: sport)
        return Player(
            id: dto.id,
            fullName: dto.fullName,
            proTeamAbbreviation: ESPNProTeamMap.abbreviation(for: dto.proTeamId, sport: sport),
            eligiblePositions: (dto.eligibleSlots ?? []).map { ESPNPositionMap.lineupSlotName(slotId: $0, sport: sport) },
            primaryPosition: position,
            injuryStatus: Player.InjuryStatus(rawValue: dto.injuryStatus ?? "ACTIVE") ?? .unknown,
            percentOwned: dto.ownership?.percentOwned ?? 0,
            percentStarted: dto.ownership?.percentStarted ?? 0,
            projectedPoints: projected,
            actualPoints: actual,
            seasonTotalPoints: seasonTotal
        )
    }

    private static func mapMatchup(_ dto: ESPNMatchupDTO) -> Matchup? {
        guard let home = dto.home, let away = dto.away else { return nil }
        return Matchup(
            id: dto.matchupPeriodId * 100_000 + home.teamId,
            week: dto.matchupPeriodId,
            homeTeamId: home.teamId,
            awayTeamId: away.teamId,
            homeScore: home.totalPoints ?? 0,
            awayScore: away.totalPoints ?? 0
        )
    }
}

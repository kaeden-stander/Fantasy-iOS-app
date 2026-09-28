import XCTest
@testable import FantasyAI

final class ESPNMapperTests: XCTestCase {
    private let sampleJSON = """
    {
      "id": 12345,
      "seasonId": 2025,
      "scoringPeriodId": 3,
      "settings": { "name": "Test League" },
      "teams": [
        {
          "id": 1,
          "location": "Test",
          "nickname": "Team",
          "owners": ["{ABC-123}"],
          "record": { "overall": { "wins": 2, "losses": 1, "ties": 0, "pointsFor": 300.5, "pointsAgainst": 250.25 } },
          "roster": {
            "entries": [
              {
                "playerId": 100,
                "lineupSlotId": 0,
                "playerPoolEntry": {
                  "player": {
                    "id": 100,
                    "fullName": "Test Quarterback",
                    "proTeamId": 1,
                    "defaultPositionId": 1,
                    "eligibleSlots": [0, 7, 20],
                    "injuryStatus": "ACTIVE",
                    "ownership": { "percentOwned": 99.5, "percentStarted": 95.0 },
                    "stats": [
                      { "scoringPeriodId": 3, "statSourceId": 0, "appliedTotal": 24.5 },
                      { "scoringPeriodId": 3, "statSourceId": 1, "appliedTotal": 20.0 },
                      { "scoringPeriodId": 1, "statSourceId": 0, "appliedTotal": 18.0 }
                    ]
                  }
                }
              },
              {
                "playerId": 101,
                "lineupSlotId": 20,
                "playerPoolEntry": {
                  "player": {
                    "id": 101,
                    "fullName": "Bench Guy",
                    "proTeamId": 6,
                    "defaultPositionId": 2,
                    "eligibleSlots": [2, 23, 20],
                    "injuryStatus": "QUESTIONABLE",
                    "ownership": { "percentOwned": 40.0, "percentStarted": 10.0 },
                    "stats": []
                  }
                }
              }
            ]
          }
        }
      ],
      "schedule": [
        {
          "matchupPeriodId": 3,
          "home": { "teamId": 1, "totalPoints": 24.5 },
          "away": { "teamId": 2, "totalPoints": 18.0 }
        }
      ]
    }
    """

    func testMapsLeagueTeamsRosterAndSchedule() throws {
        let dto = try JSONDecoder().decode(ESPNLeagueDTO.self, from: Data(sampleJSON.utf8))
        let league = ESPNMapper.map(dto: dto, sport: .football, seasonYear: 2025)

        XCTAssertEqual(league.id, 12345)
        XCTAssertEqual(league.name, "Test League")
        XCTAssertEqual(league.currentScoringPeriod, 3)
        XCTAssertEqual(league.teams.count, 1)

        let team = league.teams[0]
        XCTAssertEqual(team.name, "Test Team")
        XCTAssertEqual(team.wins, 2)

        let starters = team.roster?.starters ?? []
        let bench = team.roster?.bench ?? []
        XCTAssertEqual(starters.count, 1)
        XCTAssertEqual(bench.count, 1)

        let starter = starters[0].player
        XCTAssertEqual(starter.fullName, "Test Quarterback")
        XCTAssertEqual(starter.primaryPosition, "QB")
        XCTAssertEqual(starter.proTeamAbbreviation, "ATL")
        XCTAssertEqual(starter.projectedPoints, 20.0)
        XCTAssertEqual(starter.actualPoints, 24.5)
        XCTAssertEqual(starter.seasonTotalPoints, 42.5, accuracy: 0.001)

        XCTAssertEqual(league.matchups.count, 1)
        let matchup = league.matchups[0]
        XCTAssertEqual(matchup.week, 3)
        XCTAssertEqual(matchup.homeTeamId, 1)
        XCTAssertEqual(matchup.awayTeamId, 2)
        XCTAssertEqual(matchup.homeScore, 24.5)
        XCTAssertEqual(matchup.awayScore, 18.0)
    }
}

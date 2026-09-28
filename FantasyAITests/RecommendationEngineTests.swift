import XCTest
@testable import FantasyAI

final class RecommendationEngineTests: XCTestCase {
    private func makeTeam() -> Team {
        let starter = Player(
            id: 1, fullName: "Starter Player", proTeamAbbreviation: "ATL",
            eligiblePositions: ["QB"], primaryPosition: "QB", injuryStatus: .active,
            percentOwned: 99, percentStarted: 90, projectedPoints: 20, actualPoints: 0, seasonTotalPoints: 100
        )
        let benchPlayer = Player(
            id: 2, fullName: "Bench Player", proTeamAbbreviation: "BUF",
            eligiblePositions: ["RB"], primaryPosition: "RB", injuryStatus: .questionable,
            percentOwned: 40, percentStarted: 10, projectedPoints: 25, actualPoints: 0, seasonTotalPoints: 80
        )
        let roster = Roster(teamId: 1, slots: [
            RosterSlot(player: starter, lineupSlot: "QB", isStarting: true),
            RosterSlot(player: benchPlayer, lineupSlot: "BENCH", isStarting: false)
        ])
        return Team(id: 1, name: "My Team", ownerName: "Me", ownerGUIDs: ["{ABC-123}"], wins: 5, losses: 2, ties: 0, pointsFor: 500, pointsAgainst: 400, roster: roster)
    }

    func testStartSitPromptMentionsEveryRosterPlayer() {
        let prompt = RecommendationEngine.buildStartSitPrompt(team: makeTeam(), opponent: nil)
        XCTAssertTrue(prompt.contains("Starter Player"))
        XCTAssertTrue(prompt.contains("Bench Player"))
        XCTAssertTrue(prompt.contains("benched"))
        XCTAssertTrue(prompt.contains("starting"))
    }

    func testParseRecommendationsHandlesPlainJSON() {
        let json = """
        [
          {"kind": "start_sit", "headline": "Start Bench Player", "reasoning": "Higher ceiling.", "confidence": 0.8, "suggestedActions": ["Bench Starter Player"]}
        ]
        """
        let recommendations = RecommendationEngine.parseRecommendations(from: json)
        XCTAssertEqual(recommendations.count, 1)
        XCTAssertEqual(recommendations[0].kind, .startSit)
        XCTAssertEqual(recommendations[0].headline, "Start Bench Player")
        XCTAssertEqual(recommendations[0].suggestedActions, ["Bench Starter Player"])
    }

    func testParseRecommendationsPullsJSONOutOfSurroundingProse() {
        let response = """
        Sure, here's my analysis:
        [{"kind": "waiver", "headline": "Pick up X", "reasoning": "Trending up.", "confidence": 0.6, "suggestedActions": []}]
        Let me know if you want more detail.
        """
        let recommendations = RecommendationEngine.parseRecommendations(from: response)
        XCTAssertEqual(recommendations.count, 1)
        XCTAssertEqual(recommendations[0].kind, .waiver)
    }

    func testParseRecommendationsReturnsEmptyForGarbage() {
        XCTAssertTrue(RecommendationEngine.parseRecommendations(from: "not json at all").isEmpty)
    }
}

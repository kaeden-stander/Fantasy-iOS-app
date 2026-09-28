import XCTest
@testable import FantasyAI

final class SportTests: XCTestCase {
    func testESPNGameAbbreviations() {
        XCTAssertEqual(Sport.football.espnGameAbbreviation, "ffl")
        XCTAssertEqual(Sport.basketball.espnGameAbbreviation, "fba")
        XCTAssertEqual(Sport.baseball.espnGameAbbreviation, "flb")
        XCTAssertEqual(Sport.hockey.espnGameAbbreviation, "fhl")
    }

    func testLeagueURLIncludesRequestedViews() {
        let url = ESPNEndpoints.leagueURL(sport: .football, seasonYear: 2025, leagueId: 12345, views: ["mTeam", "mRoster"])
        let string = url.absoluteString
        XCTAssertTrue(string.contains("/games/ffl/seasons/2025/segments/0/leagues/12345"))
        XCTAssertTrue(string.contains("view=mTeam"))
        XCTAssertTrue(string.contains("view=mRoster"))
    }
}

import Foundation

/// Builds prompts from live roster/matchup data and asks Claude for start/sit and trade
/// advice. Claude is told to answer with only a JSON array so the response can be parsed
/// straight into Recommendation values; if it doesn't (a stray sentence, code fences), the
/// parser pulls out the first "[...]" block it finds before decoding.
final class RecommendationEngine {
    private let claudeClient: ClaudeClient

    init(claudeClient: ClaudeClient) {
        self.claudeClient = claudeClient
    }

    func startSitRecommendations(for team: Team, opponent: Team?, sport: Sport) async throws -> [Recommendation] {
        let prompt = Self.buildStartSitPrompt(team: team, opponent: opponent)
        let response = try await claudeClient.send(system: Self.systemPrompt(sport: sport), userMessage: prompt)
        return Self.parseRecommendations(from: response)
    }

    func evaluateTrade(_ proposal: TradeProposal, myTeam: Team, sport: Sport) async throws -> [Recommendation] {
        let prompt = Self.buildTradePrompt(proposal: proposal, myTeam: myTeam)
        let response = try await claudeClient.send(system: Self.systemPrompt(sport: sport), userMessage: prompt)
        return Self.parseRecommendations(from: response)
    }

    static func systemPrompt(sport: Sport) -> String {
        """
        You are a fantasy \(sport.displayName.lowercased()) analyst. Give direct, data-driven \
        advice about lineup decisions and trades, based only on the stats provided, not on a \
        player's reputation. Respond with ONLY a JSON array, no prose outside the JSON. Each \
        element must have these fields: kind (one of "start_sit", "waiver", "trade"), headline \
        (string), reasoning (string, 2-4 sentences), confidence (number from 0 to 1), \
        suggestedActions (array of strings, can be empty).
        """
    }

    static func buildStartSitPrompt(team: Team, opponent: Team?) -> String {
        var lines = ["My roster for \(team.name):"]
        for slot in team.roster?.slots ?? [] {
            let player = slot.player
            lines.append(
                "- \(player.fullName) (\(player.primaryPosition), \(player.proTeamAbbreviation)): " +
                "projected \(player.projectedPoints) pts, season total \(player.seasonTotalPoints), " +
                "injury status \(player.injuryStatus.rawValue), currently " +
                "\(slot.isStarting ? "starting" : "benched") in \(slot.lineupSlot)"
            )
        }
        if let opponent {
            lines.append("Opponent this week: \(opponent.name), record \(opponent.wins)-\(opponent.losses)-\(opponent.ties).")
        }
        lines.append("Recommend any start/sit changes that would improve my projected score this week. Only flag real improvements.")
        return lines.joined(separator: "\n")
    }

    static func buildTradePrompt(proposal: TradeProposal, myTeam: Team) -> String {
        var lines = ["Evaluate this trade for my team, \(myTeam.name)."]
        lines.append("Players I would give up:")
        for player in proposal.playersOffered {
            lines.append("- \(player.fullName) (\(player.primaryPosition)): season total \(player.seasonTotalPoints), projected \(player.projectedPoints)")
        }
        lines.append("Players I would receive:")
        for player in proposal.playersRequested {
            lines.append("- \(player.fullName) (\(player.primaryPosition)): season total \(player.seasonTotalPoints), projected \(player.projectedPoints)")
        }
        lines.append("Tell me whether to accept, and why, weighing roster balance and remaining value.")
        return lines.joined(separator: "\n")
    }

    static func parseRecommendations(from response: String) -> [Recommendation] {
        guard let jsonText = extractJSONArray(from: response),
              let jsonData = jsonText.data(using: .utf8) else { return [] }

        struct RawRecommendation: Decodable {
            let kind: String
            let headline: String
            let reasoning: String
            let confidence: Double
            let suggestedActions: [String]
        }

        guard let raw = try? JSONDecoder().decode([RawRecommendation].self, from: jsonData) else { return [] }
        return raw.map { entry in
            Recommendation(
                id: UUID(),
                kind: RecommendationKind(rawValue: entry.kind) ?? .startSit,
                headline: entry.headline,
                reasoning: entry.reasoning,
                confidence: entry.confidence,
                suggestedActions: entry.suggestedActions
            )
        }
    }

    private static func extractJSONArray(from text: String) -> String? {
        guard let start = text.firstIndex(of: "["), let end = text.lastIndex(of: "]"), start < end else { return nil }
        return String(text[start...end])
    }
}

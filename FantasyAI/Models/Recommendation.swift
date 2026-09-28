import Foundation

enum RecommendationKind: String, Codable {
    case startSit = "start_sit"
    case waiver = "waiver"
    case trade = "trade"
}

struct Recommendation: Identifiable, Codable {
    let id: UUID
    let kind: RecommendationKind
    let headline: String
    let reasoning: String
    let confidence: Double
    let suggestedActions: [String]
}

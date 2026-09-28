import Foundation

/// A thin client for Anthropic's Messages API. The app calls this directly from the
/// device using the user's own API key (see SecureConfig) — there's no backend server.
final class ClaudeClient {
    enum ClaudeClientError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case httpError(Int, String?)
        case emptyContent

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "No Anthropic API key is set."
            case .invalidResponse:
                return "Claude returned an unexpected response."
            case .httpError(let code, let message):
                return "Claude API request failed (HTTP \(code))\(message.map { ": \($0)" } ?? "")."
            case .emptyContent:
                return "Claude's response didn't contain any text."
            }
        }
    }

    private let model: String
    private let session: URLSession
    private let apiKeyProvider: () -> String?

    init(model: String = "claude-sonnet-5", session: URLSession = .shared, apiKeyProvider: @escaping () -> String?) {
        self.model = model
        self.session = session
        self.apiKeyProvider = apiKeyProvider
    }

    func send(system: String, userMessage: String, maxTokens: Int = 1024) async throws -> String {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw ClaudeClientError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [["role": "user", "content": userMessage]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data))?.error.message
            throw ClaudeClientError.httpError(httpResponse.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = decoded.content.first(where: { $0.type == "text" })?.text else {
            throw ClaudeClientError.emptyContent
        }
        return text
    }
}

private struct ClaudeResponse: Decodable {
    let content: [ClaudeContentBlock]
}

private struct ClaudeContentBlock: Decodable {
    let type: String
    let text: String?
}

private struct ClaudeErrorResponse: Decodable {
    struct ErrorDetail: Decodable {
        let message: String
    }
    let error: ErrorDetail
}

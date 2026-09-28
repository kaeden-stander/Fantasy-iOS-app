import Foundation

/// The two cookies ESPN's private fantasy API checks for. Captured from a logged-in
/// WKWebView session (see ESPNAuthWebView) since ESPN has no OAuth flow for this API.
struct ESPNCredentials: Codable, Equatable {
    let swid: String
    let espnS2: String
}

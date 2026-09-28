import Foundation

/// Holds the user's own Anthropic API key, entered in Settings and stored in the Keychain.
/// The app calls the Claude API directly from the device with this key — there's no backend.
///
/// Not @MainActor: ClaudeClient reads `anthropicAPIKey` from a plain, non-isolated closure
/// (see AppState), and this type's own methods are only ever called from view code that's
/// already on the main thread.
final class SecureConfig: ObservableObject {
    @Published private(set) var anthropicAPIKey: String?

    private let keychain: KeychainStore
    private let apiKeyStorageKey = "anthropic.apiKey"

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
        if let data = keychain.read(forKey: apiKeyStorageKey) {
            anthropicAPIKey = String(data: data, encoding: .utf8)
        }
    }

    func saveAPIKey(_ key: String) {
        anthropicAPIKey = key
        guard let data = key.data(using: .utf8) else { return }
        keychain.save(data, forKey: apiKeyStorageKey)
    }

    func clearAPIKey() {
        anthropicAPIKey = nil
        keychain.delete(forKey: apiKeyStorageKey)
    }
}

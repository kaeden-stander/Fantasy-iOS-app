import Foundation
import Combine

// Not @MainActor: ESPNClient reads `credentials` from a plain, non-isolated closure
// (see AppState), and this type's own methods are only ever called from view code
// that's already on the main thread, so isolating the type adds nothing but friction.
final class ESPNAuthManager: ObservableObject {
    @Published private(set) var credentials: ESPNCredentials?

    private let keychain: KeychainStore
    private let storageKey = "espn.credentials"

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
        self.credentials = Self.loadCredentials(from: keychain, key: storageKey)
    }

    var isAuthenticated: Bool { credentials != nil }

    func save(_ credentials: ESPNCredentials) {
        self.credentials = credentials
        guard let data = try? JSONEncoder().encode(credentials) else { return }
        keychain.save(data, forKey: storageKey)
    }

    func signOut() {
        credentials = nil
        keychain.delete(forKey: storageKey)
    }

    private static func loadCredentials(from keychain: KeychainStore, key: String) -> ESPNCredentials? {
        guard let data = keychain.read(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ESPNCredentials.self, from: data)
    }
}

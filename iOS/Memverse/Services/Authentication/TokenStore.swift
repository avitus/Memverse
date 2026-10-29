import Foundation
import Security

struct TokenSet: Codable, Equatable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }
}

protocol TokenStoring: Sendable {
    func load() throws -> TokenSet?
    func save(_ tokens: TokenSet) throws
    func clear() throws
}

final class MemoryTokenStore: TokenStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var tokens: TokenSet?

    func load() throws -> TokenSet? {
        lock.lock()
        defer { lock.unlock() }
        return tokens
    }

    func save(_ tokens: TokenSet) throws {
        lock.lock()
        defer { lock.unlock() }
        self.tokens = tokens
    }

    func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        tokens = nil
    }
}

struct KeychainTokenStore: TokenStoring {
    private let service = "com.veetle.Memverse.oauth"
    private let account = "tokens"

    func load() throws -> TokenSet? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unreadable
        }
        return try JSONDecoder().decode(TokenSet.self, from: data)
    }

    func save(_ tokens: TokenSet) throws {
        let data = try JSONEncoder().encode(tokens)
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery() as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = baseQuery()
            insert[kSecValueData as String] = data
            let added = SecItemAdd(insert as CFDictionary, nil)
            guard added == errSecSuccess else { throw KeychainError.unreadable }
            return
        }
        guard status == errSecSuccess else { throw KeychainError.unreadable }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unreadable
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum KeychainError: Error {
    case unreadable
}

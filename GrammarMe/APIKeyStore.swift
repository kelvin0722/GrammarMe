import Foundation
import Security

nonisolated protocol APIKeyStoring: Sendable {
    func load() throws -> String?
    func save(_ key: String) throws
    func delete() throws
}

nonisolated enum APIKeyStoreError: LocalizedError {
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .keychain(let status):
            "GrammarMe could not access the API key in Keychain (\(status))."
        }
    }
}

nonisolated struct KeychainAPIKeyStore: APIKeyStoring {
    private let service: String
    private let account: String
    private let legacyDefaultsKey: String

    init(
        service: String = "com.nbttechnologies.GrammarMe",
        account: String = "openai-api-key",
        legacyDefaultsKey: String = AppSettings.apiKey
    ) {
        self.service = service
        self.account = account
        self.legacyDefaultsKey = legacyDefaultsKey
    }

    func load() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        guard status == errSecItemNotFound else { throw APIKeyStoreError.keychain(status) }
        return try migrateLegacyKeyIfNeeded()
    }

    func save(_ key: String) throws {
        let data = Data(key.utf8)
        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else { throw APIKeyStoreError.keychain(updateStatus) }
        var query = baseQuery
        query[kSecValueData as String] = data
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw APIKeyStoreError.keychain(addStatus) }
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyStoreError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func migrateLegacyKeyIfNeeded() throws -> String? {
        let defaults = UserDefaults.standard
        guard let legacyKey = defaults.string(forKey: legacyDefaultsKey), !legacyKey.isEmpty else { return nil }
        try save(legacyKey)
        defaults.removeObject(forKey: legacyDefaultsKey)
        return legacyKey
    }
}

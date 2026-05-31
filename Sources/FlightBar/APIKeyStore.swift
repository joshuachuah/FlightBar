import Foundation
import Security

enum APIKeyStore {
    static let didChangeNotification = Notification.Name("FlightBarAPIKeyDidChange")

    private static let service = "com.flightbar.app"
    private static let account = "aviationstack_api_key"
    private static let legacyDefaultsKey = "aviationstack_api_key"

    static func load() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data,
                  let key = String(data: data, encoding: .utf8) else {
                throw APIKeyStoreError.invalidData
            }
            return key
        case errSecItemNotFound:
            return try migrateLegacyDefaultsKey()
        default:
            throw APIKeyStoreError.unexpectedStatus(status)
        }
    }

    static func save(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            try delete()
            return
        }

        let data = Data(trimmed.utf8)
        let attributes = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            postChangeNotification()
        case errSecItemNotFound:
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw APIKeyStoreError.unexpectedStatus(addStatus)
            }
            postChangeNotification()
        default:
            throw APIKeyStoreError.unexpectedStatus(updateStatus)
        }
    }

    static func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyStoreError.unexpectedStatus(status)
        }
        postChangeNotification()
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func postChangeNotification() {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: didChangeNotification, object: nil)
            }
        }
    }

    private static func migrateLegacyDefaultsKey() throws -> String? {
        guard let key = UserDefaults.standard.string(forKey: legacyDefaultsKey) else {
            return nil
        }

        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
            return nil
        }

        try save(trimmed)
        UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
        return trimmed
    }
}

enum APIKeyStoreError: LocalizedError {
    case invalidData
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "The saved API key could not be read."
        case .unexpectedStatus(let status):
            return "Keychain returned status \(status)."
        }
    }
}

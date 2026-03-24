import Foundation
import Security

enum KeychainService {

    enum KeychainError: Error {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case dataConversionError
    }

    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Convenience Keys

    static let openAIAPIKeyIdentifier = "com.axiom.openai-api-key"
    static let appleUserIdIdentifier = "com.axiom.apple-user-id"

    static var openAIAPIKey: String? {
        get {
            // Try keychain first, fall back to UserDefaults
            if let key = load(key: openAIAPIKeyIdentifier), !key.isEmpty {
                return key
            }
            return UserDefaults.standard.string(forKey: "fallback_api_key")
        }
        set {
            if let newValue {
                try? save(key: openAIAPIKeyIdentifier, value: newValue)
                // Also store in UserDefaults as fallback (keychain can fail on first launch)
                UserDefaults.standard.set(newValue, forKey: "fallback_api_key")
            } else {
                delete(key: openAIAPIKeyIdentifier)
                UserDefaults.standard.removeObject(forKey: "fallback_api_key")
            }
        }
    }
}

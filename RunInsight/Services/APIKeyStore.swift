//
//  APIKeyStore.swift
//  RunInsight
//
//  Created by Codex on 2026-05-08.
//

import Foundation
import Security

enum APIKeyStoreError: LocalizedError {
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            String(format: NSLocalizedString("Keychain operation failed with status %d.", comment: ""), status)
        }
    }
}

struct APIKeyStore {
    private let service: String
    private let account = "apiKey"

    init(provider: AIProvider) {
        service = provider.keychainService
    }

    func apiKey() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw APIKeyStoreError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func save(apiKey: String) throws {
        let data = Data(apiKey.utf8)
        var query = baseQuery
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw APIKeyStoreError.unexpectedStatus(addStatus)
            }
            return
        }

        guard status == errSecSuccess else {
            throw APIKeyStoreError.unexpectedStatus(status)
        }
    }

    func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyStoreError.unexpectedStatus(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

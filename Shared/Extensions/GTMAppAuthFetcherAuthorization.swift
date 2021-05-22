//
//  GTMAppAuthFetcherAuthorization.swift
//  Potori
//
//  Created by Lucka on 22/5/2021.
//

import GTMAppAuth

extension GTMAppAuthFetcherAuthorization {
    private static let kGTMOAuth2AccountName = "OAuth"
    private static let kGTMOAuth2AccountGroupName: String = {
        let prefix = Bundle.main.infoDictionary?["CDAppIdentifierPrefix"] as? String
        return "\(prefix ?? "")dev.lucka.Potori"
    }()
}

extension GTMAppAuthFetcherAuthorization {
    static func fromSharedKeychain(forName keychainItemName: String) -> GTMAppAuthFetcherAuthorization? {
        var query = Self.sharedKeychainQuery(for: keychainItemName)
        query[kSecReturnData] = kCFBooleanTrue
        query[kSecMatchLimit] = kSecMatchLimitOne
        var authRef: CFTypeRef? = nil
        guard
            SecItemCopyMatching(query as CFDictionary, &authRef) == errSecSuccess,
            let authData = authRef?.copy() as? Data,
            let auth = try? NSKeyedUnarchiver.unarchivedObject(ofClass: self, from: authData)
        else {
            return nil
        }
        return auth
    }
    
    @discardableResult
    static func save(
        _ auth: GTMAppAuthFetcherAuthorization,
        toSharedKeychainForName keychainItemName: String
    ) -> Bool {
        guard
            let authData = try? NSKeyedArchiver.archivedData(withRootObject: auth, requiringSecureCoding: true)
        else {
            return false
        }
        var attributes = sharedKeychainQuery(for: keychainItemName)
        attributes[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        attributes[kSecValueData] = authData
        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    @discardableResult
    static func removeFromSharedKeychain(forName keychainItemName: String) -> Bool {
        let attributes = sharedKeychainQuery(for: keychainItemName)
        return SecItemDelete(attributes as CFDictionary) != noErr
    }
    
    private static func sharedKeychainQuery(for service: String) -> [ CFString : Any ] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: kGTMOAuth2AccountName,
            kSecAttrAccessGroup: kGTMOAuth2AccountGroupName,
        ] as [ CFString : Any ]
    }
}

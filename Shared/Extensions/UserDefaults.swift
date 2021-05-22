//
//  UserDefaults.swift
//  Potori
//
//  Created by Lucka on 21/5/2021.
//

import Foundation

extension UserDefaults {
    static let shared: UserDefaults = {
        guard let store = UserDefaults(suiteName: FileManager.appGroupIdentifier) else {
            return standard
        }
        store.register()
        return store
    }()
}

extension UserDefaults {
    struct General {
        static let keyRefreshOnOpen = "pref.general.refreshOnOpen"
        static var refreshOnOpen: Bool { shared.bool(forKey: keyRefreshOnOpen) }
        
        static let keyBackgroundRefresh = "pref.general.backgroundRefresh"
        static var backgroundRefresh: Bool { shared.bool(forKey: keyBackgroundRefresh) }

        static let keyQueryAfterLatest = "pref.general.queryAfterLatest"
        static var queryAfterLatest: Bool { shared.bool(forKey: keyQueryAfterLatest) }
        
        fileprivate static func register(_ store: UserDefaults, migrate: Bool) {
            store.register(defaults: [
                keyRefreshOnOpen    : migrate ? standard.bool(forKey: keyRefreshOnOpen      ) : false,
                keyBackgroundRefresh: migrate ? standard.bool(forKey: keyBackgroundRefresh  ) : false,
                keyQueryAfterLatest : migrate ? standard.bool(forKey: keyQueryAfterLatest   ) : true,
            ])
            if migrate {
                standard.removeObject(forKey: keyRefreshOnOpen)
                standard.removeObject(forKey: keyBackgroundRefresh)
                standard.removeObject(forKey: keyQueryAfterLatest)
            }
        }
    }
    struct Google {
        static let keySync = "pref.google.sync"
        static var sync: Bool { shared.bool(forKey: keySync) }
        
        fileprivate static func register(_ store: UserDefaults, migrate: Bool) {
            store.register(defaults: [
                keySync: migrate ? standard.bool(forKey: keySync) : false
            ])
            if migrate {
                standard.removeObject(forKey: keySync)
            }
        }
    }
    
    private func register() {
        let migrate = Self.standard.dictionaryRepresentation().keys.contains(General.keyRefreshOnOpen)
        General.register(self, migrate: migrate)
        Google.register(self, migrate: migrate)
    }
}

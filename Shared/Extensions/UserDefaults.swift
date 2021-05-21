//
//  UserDefaults.swift
//  Potori
//
//  Created by Lucka on 21/5/2021.
//

import Foundation

extension UserDefaults {
    static let shared = UserDefaults(suiteName: FileManager.appGroupIdentifier) ?? standard
}

extension UserDefaults {
    struct General {
        static let keyRefreshOnOpen = "pref.general.refreshOnOpen"
        static var refreshOnOpen: Bool { shared.bool(forKey: keyRefreshOnOpen) }
        
        static let keyBackgroundRefresh = "pref.general.backgroundRefresh"
        static var backgroundRefresh: Bool { shared.bool(forKey: keyBackgroundRefresh) }

        static let keyQueryAfterLatest = "pref.general.queryAfterLatest"
        static var queryAfterLatest: Bool { shared.bool(forKey: keyQueryAfterLatest) }
        
        fileprivate static func register(migrate: Bool) {
            UserDefaults.standard.register(defaults: [
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
        
        fileprivate static func register(migrate: Bool) {
            shared.register(defaults: [
                keySync: migrate ? standard.bool(forKey: keySync) : false
            ])
            if migrate {
                standard.removeObject(forKey: keySync)
            }
        }
    }
    
    static func register() {
        let migrate = standard.dictionaryRepresentation().keys.contains(General.keyRefreshOnOpen)
        General.register(migrate: migrate)
        Google.register(migrate: migrate)
    }
}

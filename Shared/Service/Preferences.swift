//
//  Preferences.swift
//  Potori
//
//  Created by Lucka on 6/1/2021.
//

import Foundation

class Preferences {
    struct General {
        static let keyRefreshOnOpen = "pref.general.refreshOnOpen"
        static var refreshOnOpen: Bool { UserDefaults.standard.bool(forKey: keyRefreshOnOpen) }
        
        #if os(iOS)
        static let keyBackgroundRefresh = "pref.general.backgroundRefresh"
        static var backgroundRefresh: Bool { UserDefaults.standard.bool(forKey: keyBackgroundRefresh) }
        #endif

        static let keyQueryAfterLatest = "pref.general.queryAfterLatest"
        static var queryAfterLatest: Bool { UserDefaults.standard.bool(forKey: keyQueryAfterLatest) }
        
        static func register() {
            UserDefaults.standard.register(defaults: [
                keyRefreshOnOpen: false,
                keyQueryAfterLatest: true,
            ])
            #if os(iOS)
            UserDefaults.standard.register(defaults: [
                keyBackgroundRefresh: false,
            ])
            #endif
        }
    }
    struct Google {
        static let keySync = "pref.google.sync"
        static var sync: Bool { UserDefaults.standard.bool(forKey: keySync) }
        
        static func register() {
            UserDefaults.standard.register(defaults: [
                keySync: false
            ])
        }
    }
    
    static func register() {
        General.register()
        Google.register()
    }
}

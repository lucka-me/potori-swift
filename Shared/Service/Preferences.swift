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
        
        static func register() {
            UserDefaults.standard.register(defaults: [
                keyRefreshOnOpen: false
            ])
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

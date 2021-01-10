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
    }
    struct Account {
        static let keyGoogleSync = "pref.account.googleSync"
        static var googleSync: Bool { UserDefaults.standard.bool(forKey: keyGoogleSync) }
    }
}

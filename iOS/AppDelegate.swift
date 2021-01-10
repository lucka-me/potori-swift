//
//  AppDelegate.swift
//  Potori (iOS)
//
//  Created by Lucka on 2/1/2021.
//

import Foundation
import UIKit

import AppAuth

class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    var currentAuthorizationFlow: OIDExternalUserAgentSession? = nil
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let solidCurrentAuthFlow = currentAuthorizationFlow, solidCurrentAuthFlow.resumeExternalUserAgentFlow(with: url) {
            // Handle openURL of authorization
            currentAuthorizationFlow = nil
            return true
        }
        return false
    }
}

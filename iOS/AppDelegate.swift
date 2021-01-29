//
//  AppDelegate.swift
//  Potori (iOS)
//
//  Created by Lucka on 2/1/2021.
//

import BackgroundTasks
import UIKit

import AppAuth

class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        Preferences.register()
        Service.shared.registerRefresh()
        return true
    }
}

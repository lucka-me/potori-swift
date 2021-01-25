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
    
    
    private static let refreshTaskID = "labs.lucka.Potori.refresh"
    
    var currentAuthorizationFlow: OIDExternalUserAgentSession? = nil
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let solidCurrentAuthFlow = currentAuthorizationFlow, solidCurrentAuthFlow.resumeExternalUserAgentFlow(with: url) {
            // Handle openURL of authorization
            currentAuthorizationFlow = nil
            return true
        }
        return false
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        Preferences.register()
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskID, using: nil) { task in
            if let refreshTask = task as? BGAppRefreshTask {
                self.refresh(refreshTask)
            }
        }
        scheduleRefresh()
        return true
    }
    
    private func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func refresh(_ task: BGAppRefreshTask) {
        scheduleRefresh()
        Service.shared.refresh()
    }
}

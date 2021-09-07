//
//  Service.swift
//  Potori
//
//  Created by Lucka on 25/5/2021.
//

import UserNotifications

extension Service {
    func backgroundRefresh(completionHandler: @escaping () -> Void) {
        guard UserDefaults.General.backgroundRefresh else {
            completionHandler()
            return
        }
        Task {
            do {
                let count = try await refresh(throwWhenMatchRequired: true)
                if count > 0 {
                    UNUserNotificationCenter.current().push(
                        .init(localized: "notification.refresh.requiresMatch"),
                        .init(format: .init(localized: "notification.refresh.refreshFinished.desc"), count)
                    )
                }
            } catch ErrorType.matchRequired {
                UNUserNotificationCenter.current().push(
                    .init(localized: "notification.refresh.requiresMatch"),
                    .init(localized: "notification.refresh.requiresMatch.desc")
                )
                
            } catch {
                // TODO: Alert
            }
            completionHandler()
        }
    }
}

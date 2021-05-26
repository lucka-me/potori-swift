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
        let started = refresh { status, count in
            if status == .requestMatch {
                UNUserNotificationCenter.push(
                    NSLocalizedString("notification.refresh.requiresMatch", comment: "Manually Match Required"),
                    NSLocalizedString("notification.refresh.requiresMatch.desc", comment: "Manually Match Required Description")
                )
            } else if count > 0 {
                UNUserNotificationCenter.push(
                    NSLocalizedString("notification.refresh.refreshFinished", comment: "Refresh Finished"),
                    String(format: NSLocalizedString("notification.refresh.refreshFinished.desc", comment: "Refresh Finished Description"), count)
                )
            }
            completionHandler()
        }
        if !started {
            completionHandler()
        }
    }
}

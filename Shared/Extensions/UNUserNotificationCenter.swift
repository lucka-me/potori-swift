//
//  Notification.swift
//  Potori
//
//  Created by Lucka on 26/1/2021.
//

import UserNotifications

extension UNUserNotificationCenter {
    func push(_ title: String, _ body: String) {
        requestAuthorization(options: [ .alert, .provisional ]) { granted, _ in
            guard granted else {
                return
            }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            self.add(.init(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }
}

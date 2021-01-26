//
//  Notification.swift
//  Potori
//
//  Created by Lucka on 26/1/2021.
//

import UserNotifications

extension UNUserNotificationCenter {
    static func requestAuthorization() {
        Self.current().requestAuthorization(options: [ .alert, .provisional ]) { _, _ in
            // It's fine to work without notification
        }
    }
    
    static func push(_ title: String, _ body: String) {
        let center = Self.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                center.add(request, withCompletionHandler: nil)
            }
        }
    }
}

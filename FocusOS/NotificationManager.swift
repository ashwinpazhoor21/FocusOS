//
//  NotificationManager.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/3/26.
//

import Foundation
import UserNotifications
import AppKit

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // Request permission (safe to call multiple times)
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("❌ Notification auth error:", error.localizedDescription)
            } else {
                print("🔔 Notifications granted:", granted)
            }
        }
    }

    func notify(title: String, body: String, playBeep: Bool = true) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification:", error.localizedDescription)
            }
        }

        // Immediate sound feedback (optional but nice)
        if playBeep {
            DispatchQueue.main.async {
                NSSound.beep()
            }
        }
    }
}

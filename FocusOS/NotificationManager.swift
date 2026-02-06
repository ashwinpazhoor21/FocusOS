import Foundation
import UserNotifications
import AppKit

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

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
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification:", error.localizedDescription)
            }
        }

        if playBeep {
            DispatchQueue.main.async { NSSound.beep() }
        }
    }


    func scheduleDailySummaryAt8PM(body: String) {
        let center = UNUserNotificationCenter.current()

        let id = "focusos.dailySummary.8pm"

        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "FocusOS Daily Summary"
        content.body = body
        content.sound = .default

        var date = DateComponents()
        date.hour = 20
        date.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("❌ scheduleDailySummaryAt8PM error:", error.localizedDescription)
            } else {
                print("✅ Scheduled daily summary for 8:00 PM")
            }
        }
    }

    func scheduleTestSummaryIn(seconds: TimeInterval, body: String) {
        let center = UNUserNotificationCenter.current()
        let id = "focusos.dailySummary.test"

        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "FocusOS Daily Summary (Test)"
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("❌ scheduleTestSummaryIn error:", error.localizedDescription)
            } else {
                print("✅ Scheduled test summary in \(Int(seconds))s")
            }
        }
    }
}

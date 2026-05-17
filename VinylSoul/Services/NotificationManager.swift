import Foundation
import UserNotifications

struct NotificationManager {
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("Notification auth failed: \(error)")
            }
        }
    }

    func scheduleDailyInspiration() {
        let content = UNMutableNotificationContent()
        content.title = "VinylSoul"
        content.body = "今天的R&B心情是什么？🎵 打开 VinylSoul，让灵感流淌。"
        content.sound = .default

        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-inspiration",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Schedule failed: \(error)")
            }
        }
    }
}

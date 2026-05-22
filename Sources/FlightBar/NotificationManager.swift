import Foundation
import UserNotifications

struct NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error = error {
                print("Notification auth error: \(error.localizedDescription)")
            }
        }
    }

    func sendStatusChange(flight: Flight, oldStatus: FlightStatus) {
        let content = UNMutableNotificationContent()
        content.title = "\(flight.flightIATA) status changed"
        content.body = "\(oldStatus.rawValue.capitalized) → \(flight.status.rawValue.capitalized)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(flight.id.uuidString)-\(flight.status.rawValue)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
}
import Foundation
import UserNotifications

struct NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorizationIfNeeded() {
        Task {
            _ = await authorizationStatusAfterRequestIfNeeded()
        }
    }

    func sendStatusChange(flight: Flight, oldStatus: FlightStatus) {
        Task {
            if await authorizationStatusAfterRequestIfNeeded() {
                addStatusChangeNotification(flight: flight, oldStatus: oldStatus)
            } else {
                print("Notification skipped: FlightBar notifications are not authorized.")
            }
        }
    }

    private func authorizationStatusAfterRequestIfNeeded() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            do {
                return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            } catch {
                print("Notification auth error: \(error.localizedDescription)")
                return false
            }
        default:
            return false
        }
    }

    private func addStatusChangeNotification(
        flight: Flight,
        oldStatus: FlightStatus
    ) {
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

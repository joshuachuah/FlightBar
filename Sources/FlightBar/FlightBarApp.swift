import SwiftUI

@main
struct FlightBarApp: App {
    @StateObject private var tracker = FlightTracker()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(tracker)
                .frame(minWidth: 320, minHeight: 400)
        }
        .defaultSize(width: 360, height: 500)

        MenuBarExtra("FlightBar", systemImage: "airplane") {
            MenuBarView()
                .environmentObject(tracker)
        }

        Settings {
            SettingsView()
        }
    }
}

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var tracker: FlightTracker
    @State private var showingAddSheet = false
    @State private var hasAPIKey = AviationStackClient.hasConfiguredAPIKey

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if tracker.trackedFlights.isEmpty {
                emptyState
            } else {
                ForEach(tracker.trackedFlights) { tracked in
                    FlightRowView(tracked: tracked)
                        .environmentObject(tracker)
                }
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: { tracker.refreshAll() }) {
                    Label("Refresh All", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r")
                .disabled(!hasAPIKey || tracker.trackedFlights.isEmpty)

                Spacer()

                if hasAPIKey {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Flight...", systemImage: "plus")
                    }
                    .keyboardShortcut("n")
                } else {
                    SettingsLink {
                        Label("Add API Key...", systemImage: "key")
                    }
                }
            }

            Divider()

            SettingsLink {
                Label("Settings...", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit FlightBar") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .sheet(isPresented: $showingAddSheet) {
            AddFlightView()
                .environmentObject(tracker)
        }
        .onAppear {
            hasAPIKey = AviationStackClient.hasConfiguredAPIKey
        }
        .onReceive(NotificationCenter.default.publisher(for: APIKeyStore.didChangeNotification)) { _ in
            hasAPIKey = AviationStackClient.hasConfiguredAPIKey
        }
    }

    private var emptyState: some View {
        Text(hasAPIKey ? "No flights tracked" : "AviationStack API key required")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

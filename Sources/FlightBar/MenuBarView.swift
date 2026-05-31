import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var tracker: FlightTracker
    @State private var showingAddSheet = false

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

                Spacer()

                Button(action: { showingAddSheet = true }) {
                    Label("Add Flight...", systemImage: "plus")
                }
                .keyboardShortcut("n")
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
    }

    private var emptyState: some View {
        Text("No flights tracked")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

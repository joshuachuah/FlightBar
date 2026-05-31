import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var tracker: FlightTracker
    @State private var showingAddSheet = false
    @State private var hasAPIKey = AviationStackClient.hasConfiguredAPIKey

    var body: some View {
        VStack(spacing: 0) {
            if tracker.trackedFlights.isEmpty {
                emptyState
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(tracker.trackedFlights) { tracked in
                        FlightRowView(tracked: tracked)
                            .environmentObject(tracker)
                    }
                }
                .listStyle(.sidebar)
            }

            Divider()

            HStack {
                Button(action: { tracker.refreshAll() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(!hasAPIKey || tracker.trackedFlights.isEmpty)

                Spacer()

                if hasAPIKey {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Flight", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    SettingsLink {
                        Label("Settings...", systemImage: "gearshape")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
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
        VStack(spacing: 12) {
            Image(systemName: hasAPIKey ? "airplane" : "key")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(hasAPIKey ? "No flights tracked" : "AviationStack API key required")
                .font(.headline)
                .foregroundColor(.secondary)

            if hasAPIKey {
                Text("Add a flight to start tracking")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                SettingsLink {
                    Label("Settings...", systemImage: "gearshape")
                }
            }
        }
    }
}

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var tracker: FlightTracker
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            if tracker.trackedFlights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "airplane")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No flights tracked")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add a flight to start tracking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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

                Spacer()

                Button(action: { showingAddSheet = true }) {
                    Label("Add Flight", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddFlightView()
                .environmentObject(tracker)
        }
    }
}

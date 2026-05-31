import SwiftUI

struct AddFlightView: View {
    @EnvironmentObject var tracker: FlightTracker
    @Environment(\.dismiss) private var dismiss

    @State private var flightNumber = ""
    @State private var watchMode = false
    @State private var hasAPIKey = AviationStackClient.hasConfiguredAPIKey

    var body: some View {
        VStack(spacing: 14) {
            Text("Track a Flight")
                .font(.headline)

            if !hasAPIKey {
                VStack(spacing: 8) {
                    Label("AviationStack API key required", systemImage: "key")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SettingsLink {
                        Label("Settings...", systemImage: "gearshape")
                    }
                }
            }

            TextField("Flight number (e.g. SQ321)", text: $flightNumber)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            Toggle("Watch mode (auto-refresh)", isOn: $watchMode)
                .font(.caption)

            HStack(spacing: 8) {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Add") {
                    let trimmed = flightNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    tracker.addFlight(trimmed, watch: watchMode)
                    if watchMode { tracker.startWatchTimer() }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasAPIKey)
            }
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            hasAPIKey = AviationStackClient.hasConfiguredAPIKey
        }
        .onReceive(NotificationCenter.default.publisher(for: APIKeyStore.didChangeNotification)) { _ in
            hasAPIKey = AviationStackClient.hasConfiguredAPIKey
        }
    }
}

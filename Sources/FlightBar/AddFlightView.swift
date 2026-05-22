import SwiftUI

struct AddFlightView: View {
    @EnvironmentObject var tracker: FlightTracker
    @Environment(\.dismiss) private var dismiss

    @State private var flightNumber = ""
    @State private var watchMode = false

    var body: some View {
        VStack(spacing: 14) {
            Text("Track a Flight")
                .font(.headline)

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
                .disabled(flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

import SwiftUI

struct SettingsView: View {
    @State private var hasAPIKey = AviationStackClient.hasConfiguredAPIKey
    @State private var statusMessage: String?
    @State private var statusIsError = false

    var body: some View {
        Form {
            Section("AviationStack") {
                Label(
                    hasAPIKey ? "API key loaded" : "API key not found",
                    systemImage: hasAPIKey ? "checkmark.circle" : "key"
                )
                .foregroundStyle(hasAPIKey ? .green : .secondary)

                Text("FlightBar reads `AVIATIONSTACK_API_KEY` from `.env` or the process environment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(APIKeyStore.dotenvLocationsDescription)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Button("Reload") {
                    reloadAPIKey()
                }
                .keyboardShortcut(.defaultAction)

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(statusIsError ? .red : .secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 520, height: 260)
        .task {
            reloadAPIKey(showStatus: false)
        }
    }

    private func reloadAPIKey(showStatus: Bool = true) {
        do {
            _ = try APIKeyStore.load()
            hasAPIKey = AviationStackClient.hasConfiguredAPIKey
            APIKeyStore.reload()
            if showStatus {
                statusMessage = hasAPIKey ? "API key loaded." : "No API key found."
                statusIsError = !hasAPIKey
            }
        } catch {
            hasAPIKey = false
            statusMessage = error.localizedDescription
            statusIsError = true
        }
    }
}

import SwiftUI

struct SettingsView: View {
    @State private var apiKey = ""
    @State private var statusMessage: String?
    @State private var statusIsError = false

    var body: some View {
        Form {
            Section("AviationStack") {
                SecureField("API key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                Text("Stored in macOS Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Remove") {
                        removeAPIKey()
                    }
                    .disabled(apiKey.isEmpty)

                    Spacer()
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(statusIsError ? .red : .secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 460, height: 190)
        .task {
            loadAPIKey()
        }
    }

    private func loadAPIKey() {
        do {
            apiKey = try APIKeyStore.load() ?? ""
        } catch {
            showStatus(error.localizedDescription, isError: true)
        }
    }

    private func saveAPIKey() {
        do {
            try APIKeyStore.save(apiKey)
            showStatus("Saved.", isError: false)
        } catch {
            showStatus(error.localizedDescription, isError: true)
        }
    }

    private func removeAPIKey() {
        do {
            try APIKeyStore.delete()
            apiKey = ""
            showStatus("Removed.", isError: false)
        } catch {
            showStatus(error.localizedDescription, isError: true)
        }
    }

    private func showStatus(_ message: String, isError: Bool) {
        statusMessage = message
        statusIsError = isError
    }
}

import ApplicationServices
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Gesture Mapping") {
                Text("Nod sends this input")
                TextField("Accept payload", text: $appState.acceptPayload)
                    .textFieldStyle(.roundedBorder)

                Text("Shake sends this input")
                TextField("Reject payload", text: $appState.rejectPayload)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Sensitivity") {
                Slider(value: $appState.sensitivity, in: 0.6...1.6, step: 0.1)
                Text("Higher sensitivity makes smaller head movements count.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                Text("Accessibility is required so ClaudeNod can send keyboard input to the frontmost Claude Code app or terminal.")
                    .font(.caption)
                Button("Open Accessibility Settings") {
                    openAccessibilitySettings()
                }
            }

            Section("How v1 Works") {
                Text("1. Open a Claude Code confirmation.")
                Text("2. Arm ClaudeNod from the menu bar.")
                Text("3. Nod to accept or shake to reject.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

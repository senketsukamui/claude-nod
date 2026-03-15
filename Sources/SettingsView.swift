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

            Section("Prompt Detection") {
                Toggle("Auto-arm when Claude confirmation is visible", isOn: $appState.autoArmEnabled)
                Text("The easiest path is launching Claude through the ClaudeNod wrapper. Then the app reads real Claude output instead of guessing from the screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Wrapper status: \(appState.wrapperStatus)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Run the repo's `bin/claudenod` script instead of `claude` to get the easiest setup.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                Text("If you use the ClaudeNod wrapper, Accessibility and screen capture are optional. They are only needed for the older fallback mode that controls an already-open host app directly.")
                    .font(.caption)
                Text(appState.accessibilityStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(appState.screenCaptureStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Current app path: \(appState.runningAppPath)")
                    .font(.caption2)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Grant Required Permissions") {
                        appState.requestRequiredPermissions()
                    }
                    Button("Refresh Status") {
                        appState.refreshAccessibilityStatus()
                        appState.refreshScreenCaptureStatus()
                    }
                }
                Button("Open Accessibility Settings") {
                    appState.openAccessibilitySettings()
                }
                Button("Open Screen Capture Settings") {
                    appState.openScreenCaptureSettings()
                }
            }

            Section("How v1 Works") {
                Text("1. Launch Claude with the ClaudeNod wrapper.")
                Text("2. Open a Claude confirmation and let ClaudeNod auto-arm.")
                Text("3. Nod to accept or shake to reject.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

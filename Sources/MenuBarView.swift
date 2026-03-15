import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var appState: AppState
    let settingsWindowID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ClaudeNod")
                    .font(.title3.weight(.semibold))
                Text("A calm little companion for Claude confirmations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            statusCard

            if appState.isArmed {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ready")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(appState.choiceGuidance)
                        .font(.callout.weight(.medium))
                    Text("Nod for the first choice. Shake for the second.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Toggle(isOn: Binding(get: { appState.isArmed }, set: { _ in appState.toggleArmed() })) {
                Text("Arm the next confirmation")
            }

            Toggle("Auto-arm when Claude asks", isOn: $appState.autoArmEnabled)

            if shouldShowPermissionsPrompt {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Wrapper mode is the easiest path. Accessibility and screen capture are only needed for fallback host control.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Grant Required Permissions") {
                        appState.requestRequiredPermissions()
                    }
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Divider()

            HStack {
                Button("Settings") {
                    NSApp.activate(ignoringOtherApps: true)
                    DispatchQueue.main.async {
                        openWindow(id: settingsWindowID)
                    }
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(18)
        .frame(width: 340)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(primaryStatusTitle)
                .font(.headline)
            Text(primaryStatusDetail)
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            labelValueRow(label: "AirPods", value: compactAirPodsStatus)
            labelValueRow(label: "Claude", value: compactWrapperStatus)
            labelValueRow(label: "Mode", value: appState.integrationStatus)

            if appState.lastAction != "No action sent" {
                labelValueRow(label: "Last response", value: appState.lastAction)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var primaryStatusTitle: String {
        if appState.isArmed {
            return "Prompt ready"
        }
        if appState.wrapperStatus.contains("Connected") {
            return "Listening for Claude"
        }
        return "Waiting for Claude"
    }

    private var primaryStatusDetail: String {
        if appState.isArmed {
            return appState.promptStatus
        }
        if appState.wrapperStatus.contains("Connected") {
            return "Keep using Claude in the wrapped terminal and ClaudeNod will wake up when a confirmation appears."
        }
        return "Launch Claude through `bin/claudenod` for the smoothest setup."
    }

    private var compactAirPodsStatus: String {
        appState.connectionStatus.hasPrefix("Connected") ? "Connected" : appState.connectionStatus
    }

    private var compactWrapperStatus: String {
        appState.wrapperStatus.contains("Connected") ? "Connected" : "Not connected"
    }

    private var shouldShowPermissionsPrompt: Bool {
        !appState.wrapperStatus.contains("Connected")
            && (!appState.accessibilityStatus.contains("granted") || !appState.screenCaptureStatus.contains("granted"))
    }

    private func labelValueRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }
}

import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var appState: AppState
    let settingsWindowID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ClaudeNod")
                    .font(.headline)
                Text("Accept or reject Claude Code prompts with AirPods head gestures.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            statusRow(title: "AirPods", value: appState.connectionStatus)
            statusRow(title: "Wrapper", value: appState.wrapperStatus)
            statusRow(title: "Accessibility", value: appState.accessibilityStatus)
            statusRow(title: "Screen", value: appState.screenCaptureStatus)
            statusRow(title: "Prompt", value: appState.promptStatus)
            statusRow(title: "Choices", value: appState.choiceGuidance)
            statusRow(title: "Prompt Text", value: appState.promptDebugPreview)
            statusRow(title: "Gesture", value: appState.gestureStatus)
            statusRow(title: "Action", value: appState.lastAction)
            statusRow(title: "Dispatch", value: appState.dispatchStatus)
            statusRow(title: "Mode", value: appState.integrationStatus)

            VStack(alignment: .leading, spacing: 6) {
                Text("Live motion")
                    .font(.subheadline.weight(.medium))
                Text("Pitch \(appState.livePitch.formatted(.number.precision(.fractionLength(2))))")
                Text("Yaw \(appState.liveYaw.formatted(.number.precision(.fractionLength(2))))")
                Text("Roll \(appState.liveRoll.formatted(.number.precision(.fractionLength(2))))")
                    .foregroundStyle(.secondary)
            }
            .font(.caption.monospacedDigit())

            Toggle(isOn: Binding(get: { appState.isArmed }, set: { _ in appState.toggleArmed() })) {
                Text("Arm next confirmation")
            }

            Toggle("Auto-arm on detected prompt", isOn: $appState.autoArmEnabled)

            HStack {
                Button("Test Accept") {
                    appState.sendTestGesture(.nod)
                }
                Button("Test Reject") {
                    appState.sendTestGesture(.shake)
                }
            }

            if appState.wrapperStatus.contains("Connected") {
                HStack {
                    Button("Choose 1") {
                        appState.choosePrimaryOption()
                    }
                    Button("Choose 2") {
                        appState.chooseSecondaryOption()
                    }
                }
            }

            if !appState.wrapperStatus.contains("Connected")
                && (!appState.accessibilityStatus.contains("granted") || !appState.screenCaptureStatus.contains("granted")) {
                Button("Grant Required Permissions") {
                    appState.requestRequiredPermissions()
                }
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
        .padding(16)
    }

    private func statusRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
        }
    }
}

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState

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
            statusRow(title: "Gesture", value: appState.gestureStatus)
            statusRow(title: "Action", value: appState.lastAction)
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

            HStack {
                Button("Test Accept") {
                    appState.sendTestGesture(.nod)
                }
                Button("Test Reject") {
                    appState.sendTestGesture(.shake)
                }
            }

            Divider()

            HStack {
                Button("Settings") {
                    appState.openSettings()
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

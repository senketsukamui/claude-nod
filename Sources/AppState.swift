import AppKit
import Combine
import CoreMotion
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var connectionStatus = "Checking AirPods motion availability..."
    @Published var gestureStatus = "No gesture detected yet"
    @Published var integrationStatus = "Not armed"
    @Published var isArmed = false
    @Published var livePitch = 0.0
    @Published var liveYaw = 0.0
    @Published var liveRoll = 0.0
    @Published var lastAction = "No action sent"
    @Published var sensitivity: Double = 1.0
    @Published var acceptPayload = "y\n"
    @Published var rejectPayload = "n\n"

    let motionService: HeadphoneMotionService
    let gestureDetector: GestureDetector
    let claudeController: ClaudeCodeController

    private var cancellables: Set<AnyCancellable> = []

    init(
        motionService: HeadphoneMotionService = HeadphoneMotionService(),
        gestureDetector: GestureDetector = GestureDetector(),
        claudeController: ClaudeCodeController = ClaudeCodeController()
    ) {
        self.motionService = motionService
        self.gestureDetector = gestureDetector
        self.claudeController = claudeController

        wireUp()
        motionService.start()
    }

    var menuBarSymbolName: String {
        if connectionStatus.hasPrefix("Connected") && isArmed {
            return "airpodsmax"
        }
        if connectionStatus.hasPrefix("Connected") {
            return "airpodspro"
        }
        return "airpods.gen3"
    }

    func toggleArmed() {
        isArmed.toggle()
        integrationStatus = isArmed ? "Armed for the next Claude confirmation" : "Not armed"
    }

    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func sendTestGesture(_ gesture: GestureKind) {
        handleGesture(gesture)
    }

    private func wireUp() {
        motionService.$connectionStatus
            .receive(on: RunLoop.main)
            .assign(to: &$connectionStatus)

        motionService.$latestSample
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] sample in
                guard let self else { return }

                livePitch = sample.pitch
                liveYaw = sample.yaw
                liveRoll = sample.roll

                if let gesture = gestureDetector.process(sample: sample, sensitivity: sensitivity) {
                    handleGesture(gesture)
                }
            }
            .store(in: &cancellables)
    }

    private func handleGesture(_ gesture: GestureKind) {
        gestureStatus = gesture.label

        guard isArmed else {
            integrationStatus = "Gesture ignored because ClaudeNod is not armed"
            return
        }

        do {
            switch gesture {
            case .nod:
                try claudeController.send(payload: acceptPayload)
                lastAction = "Accepted with nod at \(DateFormatter.actionClock.string(from: .now))"
            case .shake:
                try claudeController.send(payload: rejectPayload)
                lastAction = "Rejected with shake at \(DateFormatter.actionClock.string(from: .now))"
            }

            integrationStatus = "Action sent to the frontmost app"
            isArmed = false
        } catch {
            integrationStatus = "Could not send action: \(error.localizedDescription)"
        }
    }
}

private extension DateFormatter {
    static let actionClock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}

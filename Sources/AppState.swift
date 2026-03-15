import AppKit
import Combine
import CoreMotion
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var connectionStatus = "Checking AirPods motion availability..."
    @Published var gestureStatus = "No gesture detected yet"
    @Published var integrationStatus = "Watching for Claude confirmations"
    @Published var promptStatus = "No Claude confirmation detected"
    @Published var promptDebugPreview = "No inspected text yet"
    @Published var accessibilityStatus = "Checking Accessibility permission..."
    @Published var screenCaptureStatus = "Checking screen capture permission..."
    @Published var wrapperStatus = "No ClaudeNod wrapper session detected"
    @Published var isArmed = false
    @Published var autoArmEnabled = true
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
    let promptDetector: ClaudePromptDetector
    let accessibilityPermissionService: AccessibilityPermissionService
    let screenCapturePermissionService: ScreenCapturePermissionService
    let bridge: ClaudeNodBridge

    private var cancellables: Set<AnyCancellable> = []
    private var promptPollingTask: Task<Void, Never>?
    private var lastDetectionFingerprint = ""

    init(
        motionService: HeadphoneMotionService = HeadphoneMotionService(),
        gestureDetector: GestureDetector = GestureDetector(),
        claudeController: ClaudeCodeController = ClaudeCodeController(),
        promptDetector: ClaudePromptDetector = ClaudePromptDetector(),
        accessibilityPermissionService: AccessibilityPermissionService = AccessibilityPermissionService(),
        screenCapturePermissionService: ScreenCapturePermissionService = ScreenCapturePermissionService(),
        bridge: ClaudeNodBridge = ClaudeNodBridge()
    ) {
        self.motionService = motionService
        self.gestureDetector = gestureDetector
        self.claudeController = claudeController
        self.promptDetector = promptDetector
        self.accessibilityPermissionService = accessibilityPermissionService
        self.screenCapturePermissionService = screenCapturePermissionService
        self.bridge = bridge

        wireUp()
        motionService.start()
        refreshAccessibilityStatus()
        refreshScreenCaptureStatus()
        startPromptPolling()
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
        integrationStatus = isArmed ? "Armed for the next Claude confirmation" : "Watching for Claude confirmations"
    }

    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func sendTestGesture(_ gesture: GestureKind) {
        handleGesture(gesture)
    }

    func requestAccessibilityIfNeeded() {
        let trusted = accessibilityPermissionService.requestPrompt()
        accessibilityStatus = trusted
            ? "Accessibility granted"
            : "Accessibility not granted for \(runningAppPath)"
    }

    func requestRequiredPermissions() {
        requestAccessibilityIfNeeded()
        requestScreenCaptureIfNeeded()
        openAccessibilitySettings()
        openScreenCaptureSettings()

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            self?.refreshAccessibilityStatus()
            self?.refreshScreenCaptureStatus()
        }
    }

    func refreshAccessibilityStatus() {
        let trusted = accessibilityPermissionService.refreshTrust()
        accessibilityStatus = trusted
            ? "Accessibility granted"
            : "Accessibility not granted for \(runningAppPath)"
    }

    var runningAppPath: String {
        accessibilityPermissionService.appPath
    }

    func requestScreenCaptureIfNeeded() {
        let trusted = screenCapturePermissionService.requestPrompt()
        screenCaptureStatus = trusted ? "Screen capture granted" : "Screen capture not granted"
    }

    func refreshScreenCaptureStatus() {
        let trusted = screenCapturePermissionService.refreshTrust()
        screenCaptureStatus = trusted ? "Screen capture granted" : "Screen capture not granted"
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func openScreenCaptureSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func wireUp() {
        accessibilityPermissionService.$isTrusted
            .receive(on: RunLoop.main)
            .sink { [weak self] trusted in
                guard let self else { return }
                accessibilityStatus = trusted
                    ? "Accessibility granted"
                    : "Accessibility not granted for \(runningAppPath)"
            }
            .store(in: &cancellables)

        screenCapturePermissionService.$isTrusted
            .receive(on: RunLoop.main)
            .sink { [weak self] trusted in
                guard let self else { return }
                screenCaptureStatus = trusted ? "Screen capture granted" : "Screen capture not granted"
            }
            .store(in: &cancellables)

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

    private func startPromptPolling() {
        promptPollingTask?.cancel()
        promptPollingTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                refreshPromptDetection()
                try? await Task.sleep(for: .milliseconds(700))
            }
        }
    }

    private func refreshPromptDetection() {
        if let bridgeState = bridge.activeState() {
            wrapperStatus = "Connected to ClaudeNod wrapper"
            promptDebugPreview = bridgeState.preview
            promptStatus = bridgeState.promptVisible
                ? "Confirmation detected in \(bridgeState.hostName)"
                : "Watching \(bridgeState.hostName): \(bridgeState.evidence)"

            let fingerprint = "\(bridgeState.sessionID)|\(bridgeState.promptVisible)|\(bridgeState.evidence)"
            if autoArmEnabled, bridgeState.promptVisible, !isArmed, lastDetectionFingerprint != fingerprint {
                isArmed = true
                integrationStatus = "Auto-armed for \(bridgeState.hostName)"
            } else if !bridgeState.promptVisible, !isArmed {
                integrationStatus = "Watching for Claude confirmations"
            }

            lastDetectionFingerprint = fingerprint
            return
        }

        wrapperStatus = "No ClaudeNod wrapper session detected"

        do {
            let detection = try promptDetector.detectFrontmostPrompt()
            promptDebugPreview = detection.inspectedTextPreview
            promptStatus = detection.isConfirmationVisible
                ? "Confirmation detected in \(detection.hostName)"
                : "Watching \(detection.hostName): \(detection.evidence)"

            let fingerprint = "\(detection.hostName)|\(detection.evidence)|\(detection.isConfirmationVisible)"
            if autoArmEnabled, detection.isConfirmationVisible, !isArmed, lastDetectionFingerprint != fingerprint {
                isArmed = true
                integrationStatus = "Auto-armed for \(detection.hostName)"
            } else if !detection.isConfirmationVisible, !isArmed {
                integrationStatus = "Watching for Claude confirmations"
            }

            lastDetectionFingerprint = fingerprint
        } catch let error as PromptDetectionError {
            switch error {
            case .accessibilityDenied:
                promptStatus = "Launch Claude with the ClaudeNod wrapper, or grant Accessibility for host detection"
                promptDebugPreview = "Wrapper not active and Accessibility probe blocked"
                if !isArmed {
                    integrationStatus = "Waiting for wrapper session or Accessibility permission"
                }
            case .unsupportedHost:
                promptStatus = "Launch Claude through the ClaudeNod wrapper, or bring a supported host to the front"
                promptDebugPreview = "No active wrapper session and frontmost app is not a supported host"
                if !isArmed {
                    integrationStatus = "Watching for Claude confirmations"
                }
            }
            lastDetectionFingerprint = ""
        } catch {
            promptStatus = "Prompt detection error: \(error.localizedDescription)"
            promptDebugPreview = "Prompt detection error"
            if !isArmed {
                integrationStatus = "Watching for Claude confirmations"
            }
            lastDetectionFingerprint = ""
        }
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
                try sendActionPayload(acceptPayload)
                lastAction = "Accepted with nod at \(DateFormatter.actionClock.string(from: .now))"
            case .shake:
                try sendActionPayload(rejectPayload)
                lastAction = "Rejected with shake at \(DateFormatter.actionClock.string(from: .now))"
            }

            integrationStatus = bridge.activeState() == nil
                ? "Action sent to the frontmost app"
                : "Action sent to the ClaudeNod wrapper"
            isArmed = false
            lastDetectionFingerprint = ""
        } catch {
            integrationStatus = "Could not send action: \(error.localizedDescription)"
        }
    }

    private func sendActionPayload(_ payload: String) throws {
        if bridge.activeState() != nil {
            try bridge.send(payload: payload)
        } else {
            try claudeController.send(payload: payload)
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

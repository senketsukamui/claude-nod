import ApplicationServices
import AppKit
import Carbon.HIToolbox
import Foundation

enum ClaudeControlError: LocalizedError {
    case accessibilityDenied
    case unsupportedTarget

    var errorDescription: String? {
            switch self {
            case .accessibilityDenied:
                return "Accessibility permission is required to send approval input."
        case .unsupportedTarget:
            return "The frontmost app does not look like a supported Claude Code host yet."
        }
    }
}

final class ClaudeCodeController {
    private let supportedBundleHints = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "dev.warp.Warp-Stable",
        "com.anthropic.claudefordesktop"
    ]

    func send(payload: String) throws {
        guard AccessibilityPermissionService.probeAccessibilityAccess() else {
            throw ClaudeControlError.accessibilityDenied
        }

        guard let app = NSWorkspace.shared.frontmostApplication else {
            throw ClaudeControlError.unsupportedTarget
        }

        let bundleIdentifier = app.bundleIdentifier ?? ""
        let isSupported = supportedBundleHints.contains(where: bundleIdentifier.contains)
            || app.localizedName?.localizedCaseInsensitiveContains("Claude") == true

        guard isSupported else {
            throw ClaudeControlError.unsupportedTarget
        }

        for scalar in payload.unicodeScalars {
            if scalar == "\n" {
                sendKey(CGKeyCode(kVK_Return))
            } else {
                sendText(String(scalar))
            }
        }
    }

    private func sendText(_ text: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        down?.keyboardSetUnicodeString(stringLength: text.utf16.count, unicodeString: Array(text.utf16))
        let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        up?.keyboardSetUnicodeString(stringLength: text.utf16.count, unicodeString: Array(text.utf16))
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    private func sendKey(_ key: CGKeyCode) {
        let source = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

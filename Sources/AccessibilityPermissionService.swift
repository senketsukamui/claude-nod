import ApplicationServices
import AppKit
import Foundation

@MainActor
final class AccessibilityPermissionService: ObservableObject {
    @Published private(set) var isTrusted = false

    var appPath: String {
        Bundle.main.bundleURL.path
    }

    init() {
        refreshTrust()
    }

    @discardableResult
    func requestPrompt() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        let effectiveTrust = trusted || Self.probeAccessibilityAccess()
        isTrusted = effectiveTrust
        return effectiveTrust
    }

    @discardableResult
    func refreshTrust() -> Bool {
        let trusted = AXIsProcessTrusted()
        let effectiveTrust = trusted || Self.probeAccessibilityAccess()
        isTrusted = effectiveTrust
        return effectiveTrust
    }

    nonisolated static func probeAccessibilityAccess() -> Bool {
        let systemWideElement = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedApplicationAttribute as CFString,
            &value
        )

        switch result {
        case .success, .attributeUnsupported, .noValue:
            return true
        case .apiDisabled:
            return false
        default:
            return false
        }
    }
}

import ApplicationServices
import AppKit
import CoreGraphics
import Foundation
import Vision

struct ClaudePromptDetection {
    let isSupportedHost: Bool
    let isConfirmationVisible: Bool
    let hostName: String
    let evidence: String
    let inspectedTextPreview: String
}

enum PromptDetectionError: LocalizedError {
    case accessibilityDenied
    case unsupportedHost

    var errorDescription: String? {
        switch self {
        case .accessibilityDenied:
            return "Accessibility permission is required to inspect the frontmost app."
        case .unsupportedHost:
            return "The frontmost app is not a supported Claude Code host."
        }
    }
}

final class ClaudePromptDetector {
    private let ownBundleIdentifier = Bundle.main.bundleIdentifier ?? ""
    private let supportedBundleHints = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "dev.warp.Warp-Stable",
        "com.anthropic.claudefordesktop"
    ]

    private let confirmationHints = [
        "do you want to",
        "allow claude",
        "allow this action",
        "should i proceed",
        "approve",
        "confirm",
        "yes/no",
        "y/n",
        "press y",
        "press n",
        "enter to confirm",
        "are you sure",
        "enter to select",
        "to navigate",
        "cancel"
    ]

    func detectFrontmostPrompt() throws -> ClaudePromptDetection {
        guard AccessibilityPermissionService.probeAccessibilityAccess() else {
            throw PromptDetectionError.accessibilityDenied
        }

        guard let app = resolvedTargetApplication() else {
            throw PromptDetectionError.unsupportedHost
        }

        let bundleIdentifier = app.bundleIdentifier ?? ""
        let hostName = app.localizedName ?? bundleIdentifier
        let isSupportedHost = supportedBundleHints.contains(where: bundleIdentifier.contains)
            || hostName.localizedCaseInsensitiveContains("Claude")

        guard isSupportedHost else {
            throw PromptDetectionError.unsupportedHost
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        let inspectedText = gatherCandidateText(from: appElement)
        let ocrText = recognizedWindowText(for: app)
        let combinedText = [inspectedText, ocrText]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        let normalized = combinedText.lowercased()

        let matchingHint = confirmationHints.first(where: normalized.contains)
        let isConfirmationVisible = matchingHint != nil
        let preview = combinedText
            .replacingOccurrences(of: "\n", with: " | ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let shortenedPreview = preview.isEmpty ? "No readable text found" : String(preview.prefix(180))

        return ClaudePromptDetection(
            isSupportedHost: true,
            isConfirmationVisible: isConfirmationVisible,
            hostName: hostName,
            evidence: matchingHint ?? (combinedText.isEmpty ? "No readable confirmation text yet" : "No confirmation keywords found"),
            inspectedTextPreview: shortenedPreview
        )
    }

    private func resolvedTargetApplication() -> NSRunningApplication? {
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           isSupportedHost(frontmost),
           frontmost.bundleIdentifier != ownBundleIdentifier {
            return frontmost
        }

        guard let infoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for info in infoList {
            let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t ?? 0
            let layer = info[kCGWindowLayer as String] as? Int ?? 0
            let alpha = info[kCGWindowAlpha as String] as? Double ?? 1
            let bounds = info[kCGWindowBounds as String] as? [String: Any]
            let width = bounds?["Width"] as? Double ?? 0
            let height = bounds?["Height"] as? Double ?? 0

            guard layer == 0, alpha > 0, width > 300, height > 200 else {
                continue
            }

            guard let app = NSRunningApplication(processIdentifier: ownerPID) else {
                continue
            }

            if app.bundleIdentifier == ownBundleIdentifier {
                continue
            }

            if isSupportedHost(app) {
                return app
            }
        }

        return nil
    }

    private func isSupportedHost(_ app: NSRunningApplication) -> Bool {
        let bundleIdentifier = app.bundleIdentifier ?? ""
        let hostName = app.localizedName ?? bundleIdentifier
        return supportedBundleHints.contains(where: bundleIdentifier.contains)
            || hostName.localizedCaseInsensitiveContains("Claude")
    }

    private func gatherCandidateText(from appElement: AXUIElement) -> String {
        var chunks: [String] = []

        if let focusedWindow = readElementAttribute(.focusedWindow, from: appElement) {
            chunks.append(textBundle(from: focusedWindow, maxDepth: 3))
        }

        if let focusedElement = readElementAttribute(.focusedUIElement, from: appElement) {
            chunks.append(textBundle(from: focusedElement, maxDepth: 2))
            chunks.append(selectedText(from: focusedElement) ?? "")
        }

        if let windowList = readArrayAttribute(.windows, from: appElement) {
            for window in windowList.prefix(2) {
                chunks.append(textBundle(from: window, maxDepth: 2))
            }
        }

        return chunks
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private func textBundle(from element: AXUIElement, maxDepth: Int) -> String {
        var collected: [String] = []
        collectText(from: element, into: &collected, maxDepth: maxDepth)
        return collected.joined(separator: "\n")
    }

    private func selectedText(from element: AXUIElement) -> String? {
        readStringAttribute(.selectedText, from: element)
    }

    private func recognizedWindowText(for app: NSRunningApplication) -> String {
        guard CGPreflightScreenCaptureAccess() else {
            return ""
        }

        guard let windowID = frontmostWindowID(for: app.processIdentifier) else {
            return ""
        }

        guard let image = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            return ""
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return ""
        }

        let observations = request.results ?? []
        let text = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")

        return text
    }

    private func frontmostWindowID(for pid: pid_t) -> CGWindowID? {
        guard let infoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for info in infoList {
            let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t
            let layer = info[kCGWindowLayer as String] as? Int ?? 0
            let alpha = info[kCGWindowAlpha as String] as? Double ?? 1
            let bounds = info[kCGWindowBounds as String] as? [String: Any]
            let width = bounds?["Width"] as? Double ?? 0
            let height = bounds?["Height"] as? Double ?? 0

            guard ownerPID == pid, layer == 0, alpha > 0, width > 300, height > 200 else {
                continue
            }

            if let windowID = info[kCGWindowNumber as String] as? UInt32 {
                return windowID
            }
        }

        return nil
    }

    private func collectText(from element: AXUIElement, into collected: inout [String], maxDepth: Int) {
        guard maxDepth >= 0 else { return }

        for attribute in [NSAccessibility.Attribute.value, .description, .title, .help] {
            if let value = readStringAttribute(attribute, from: element), !value.isEmpty {
                collected.append(value)
            }
        }

        guard maxDepth > 0 else { return }

        guard let children = readArrayAttribute(.children, from: element) else {
            return
        }

        for child in children.prefix(20) {
            collectText(from: child, into: &collected, maxDepth: maxDepth - 1)
        }
    }

    private func readStringAttribute(_ attribute: NSAccessibility.Attribute, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute.rawValue as CFString, &value)
        guard result == .success else { return nil }
        return value as? String
    }

    private func readElementAttribute(_ attribute: NSAccessibility.Attribute, from element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute.rawValue as CFString, &value)
        guard result == .success else { return nil }
        return value as! AXUIElement?
    }

    private func readArrayAttribute(_ attribute: NSAccessibility.Attribute, from element: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute.rawValue as CFString, &value)
        guard result == .success else { return nil }
        return value as? [AXUIElement]
    }
}

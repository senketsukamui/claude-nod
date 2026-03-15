import CoreGraphics
import Foundation

@MainActor
final class ScreenCapturePermissionService: ObservableObject {
    @Published private(set) var isTrusted = false

    init() {
        refreshTrust()
    }

    @discardableResult
    func requestPrompt() -> Bool {
        let trusted = CGRequestScreenCaptureAccess()
        isTrusted = trusted
        return trusted
    }

    @discardableResult
    func refreshTrust() -> Bool {
        let trusted = CGPreflightScreenCaptureAccess()
        isTrusted = trusted
        return trusted
    }
}

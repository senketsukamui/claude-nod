import AppKit
import SwiftUI

@MainActor
final class ChoiceOverlayController {
    private var panel: NSPanel?
    private var hostingController: NSHostingController<ChoiceOverlayView>?

    func update(isVisible: Bool, guidance: String) {
        if isVisible {
            show(guidance: guidance)
        } else {
            hide()
        }
    }

    private func show(guidance: String) {
        let view = ChoiceOverlayView(guidance: guidance)

        if let hostingController {
            hostingController.rootView = view
        } else {
            let hostingController = NSHostingController(rootView: view)
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 150),
                styleMask: [.nonactivatingPanel, .hudWindow],
                backing: .buffered,
                defer: false
            )
            panel.level = .statusBar
            panel.isFloatingPanel = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.hidesOnDeactivate = false
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.contentViewController = hostingController

            self.panel = panel
            self.hostingController = hostingController
        }

        guard let panel else { return }

        if let screen = NSScreen.main?.visibleFrame {
            let origin = NSPoint(x: screen.maxX - panel.frame.width - 24, y: screen.maxY - panel.frame.height - 40)
            panel.setFrameOrigin(origin)
        }

        panel.orderFrontRegardless()
    }

    private func hide() {
        panel?.orderOut(nil)
    }
}

private struct ChoiceOverlayView: View {
    let guidance: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ClaudeNod")
                .font(.headline.weight(.semibold))
            Text("Take a breath, then choose.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(guidance)
                .font(.callout.weight(.medium))
            Text("Nod for the first choice. Shake for the second.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(width: 320)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

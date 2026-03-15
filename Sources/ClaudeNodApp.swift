import AppKit
import SwiftUI

@main
struct ClaudeNodApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()
    private let settingsWindowID = "claudenod-settings"

    var body: some Scene {
        MenuBarExtra("ClaudeNod", systemImage: appState.menuBarSymbolName) {
            MenuBarView(settingsWindowID: settingsWindowID)
                .environmentObject(appState)
                .frame(width: 320)
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: settingsWindowID) {
            SettingsView()
                .environmentObject(appState)
                .frame(width: 460, height: 360)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

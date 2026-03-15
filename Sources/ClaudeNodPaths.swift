import Foundation

enum ClaudeNodPaths {
    static let supportDirectoryURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSString(string: "~/Library/Application Support").expandingTildeInPath)
        let directory = appSupport.appendingPathComponent("ClaudeNod", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    static let stateFileURL = supportDirectoryURL.appendingPathComponent("bridge-state.json")
    static let socketURL = supportDirectoryURL.appendingPathComponent("bridge.sock")
}

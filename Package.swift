// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ClaudeNod",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClaudeNod", targets: ["ClaudeNod"])
    ],
    targets: [
        .executableTarget(
            name: "ClaudeNod"),
    ]
)


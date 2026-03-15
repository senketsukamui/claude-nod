import Darwin
import Foundation

struct ClaudeNodBridgeState: Codable {
    let sessionID: String
    let pid: Int32
    let hostName: String
    let promptVisible: Bool
    let evidence: String
    let preview: String
    let guidance: String?
    let nodSequence: [String]?
    let shakeSequence: [String]?
    let updatedAt: Date

    var isFresh: Bool {
        Date().timeIntervalSince(updatedAt) < 5
    }
}

enum ClaudeNodBridgeError: LocalizedError {
    case inactiveSession
    case socketUnavailable

    var errorDescription: String? {
        switch self {
        case .inactiveSession:
            return "ClaudeNod wrapper session is not active."
        case .socketUnavailable:
            return "ClaudeNod could not reach the active wrapper session."
        }
    }
}

final class ClaudeNodBridge {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func activeState() -> ClaudeNodBridgeState? {
        guard let data = try? Data(contentsOf: ClaudeNodPaths.stateFileURL),
              let state = try? decoder.decode(ClaudeNodBridgeState.self, from: data),
              state.isFresh else {
            return nil
        }

        guard kill(state.pid, 0) == 0 else {
            return nil
        }

        return state
    }

    func send(payload: String) throws {
        try send(sequence: [payload])
    }

    func send(sequence: [String]) throws {
        guard activeState() != nil else {
            throw ClaudeNodBridgeError.inactiveSession
        }

        let socketPath = ClaudeNodPaths.socketURL.path
        let socketFD = socket(AF_UNIX, Int32(SOCK_STREAM), 0)
        guard socketFD >= 0 else {
            throw ClaudeNodBridgeError.socketUnavailable
        }
        defer { close(socketFD) }

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let maxLength = MemoryLayout.size(ofValue: address.sun_path)
        let pathBytes = Array(socketPath.utf8)
        guard pathBytes.count < maxLength else {
            throw ClaudeNodBridgeError.socketUnavailable
        }

        withUnsafeMutableBytes(of: &address.sun_path) { rawBuffer in
            rawBuffer.initializeMemory(as: UInt8.self, repeating: 0)
            for (index, byte) in pathBytes.enumerated() {
                rawBuffer[index] = byte
            }
        }

        let addressLength = socklen_t(MemoryLayout<sa_family_t>.size + pathBytes.count + 1)
        let connected = withUnsafePointer(to: &address) { pointer -> Int32 in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                connect(socketFD, sockaddrPointer, addressLength)
            }
        }

        guard connected == 0 else {
            throw ClaudeNodBridgeError.socketUnavailable
        }

        let command = ClaudeNodBridgeCommand(kind: "send_sequence", payloads: sequence)
        let data = try encoder.encode(command)
        let sentCount = data.withUnsafeBytes { bytes in
            Darwin.send(socketFD, bytes.baseAddress, bytes.count, 0)
        }

        guard sentCount == data.count else {
            throw ClaudeNodBridgeError.socketUnavailable
        }
    }
}

private struct ClaudeNodBridgeCommand: Codable {
    let kind: String
    let payloads: [String]
}

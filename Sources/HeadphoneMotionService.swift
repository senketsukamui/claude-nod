import CoreMotion
import Foundation

struct MotionSample {
    let timestamp: TimeInterval
    let pitch: Double
    let yaw: Double
    let roll: Double
    let rotationX: Double
    let rotationY: Double
    let rotationZ: Double
}

@MainActor
final class HeadphoneMotionService: ObservableObject {
    @Published private(set) var latestSample: MotionSample?
    @Published private(set) var connectionStatus = "AirPods motion unavailable"

    private let manager = CMHeadphoneMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else {
            connectionStatus = "AirPods motion unavailable on this Mac right now"
            return
        }

        connectionStatus = "Connected to AirPods motion stream"
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self else { return }

            if let error {
                self.connectionStatus = "Motion error: \(error.localizedDescription)"
                return
            }

            guard let motion else {
                self.connectionStatus = "Waiting for head motion samples..."
                return
            }

            let attitude = motion.attitude
            let rotationRate = motion.rotationRate

            self.latestSample = MotionSample(
                timestamp: motion.timestamp,
                pitch: attitude.pitch,
                yaw: attitude.yaw,
                roll: attitude.roll,
                rotationX: rotationRate.x,
                rotationY: rotationRate.y,
                rotationZ: rotationRate.z
            )
        }
    }
}

import Foundation

enum GestureKind {
    case nod
    case shake

    var label: String {
        switch self {
        case .nod:
            return "Nod detected"
        case .shake:
            return "Shake detected"
        }
    }
}

final class GestureDetector {
    private var recentSamples: [MotionSample] = []
    private var lastGestureTime: TimeInterval = 0
    private let cooldown: TimeInterval = 1.2
    private let windowSize = 20

    func process(sample: MotionSample, sensitivity: Double) -> GestureKind? {
        recentSamples.append(sample)
        recentSamples = Array(recentSamples.suffix(windowSize))

        guard sample.timestamp - lastGestureTime > cooldown else {
            return nil
        }

        let pitchSpan = recentSamples.map(\.pitch).span
        let yawSpan = recentSamples.map(\.yaw).span
        let rollSpan = recentSamples.map(\.roll).span
        let avgPitchRate = recentSamples.map { abs($0.rotationX) }.average
        let avgYawRate = recentSamples.map { abs($0.rotationY) }.average
        let avgRollRate = recentSamples.map { abs($0.rotationZ) }.average

        let nodThreshold = 0.28 / sensitivity
        let shakeThreshold = 0.18 / sensitivity
        let shakeRateThreshold = 0.55 / sensitivity
        let rollShakeThreshold = 0.16 / sensitivity
        let rollRateThreshold = 0.7 / sensitivity

        if pitchSpan > nodThreshold && avgPitchRate > 0.9 {
            lastGestureTime = sample.timestamp
            return .nod
        }

        let isYawShake = yawSpan > shakeThreshold && avgYawRate > shakeRateThreshold
        let isRollShake = rollSpan > rollShakeThreshold && avgRollRate > rollRateThreshold
        let looksLikeNodInstead = pitchSpan > (nodThreshold * 0.9) && avgPitchRate > 0.75

        if (isYawShake || isRollShake) && !looksLikeNodInstead {
            lastGestureTime = sample.timestamp
            return .shake
        }

        return nil
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    var span: Double {
        guard let minValue = self.min(), let maxValue = self.max() else { return 0 }
        return maxValue - minValue
    }
}

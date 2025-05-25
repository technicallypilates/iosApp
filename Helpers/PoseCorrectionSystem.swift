import Vision
import CoreML
import Foundation

struct PoseDifficulty {
    let baseTolerance: Double
    let requiredAccuracy: Double
    let xpMultiplier: Double
}

class PoseCorrectionSystem {
    // MARK: - Properties
    private let stabilityThreshold: Double = 0.8
    private let difficultyLevels: [Int: PoseDifficulty] = [
        1: PoseDifficulty(baseTolerance: 20.0, requiredAccuracy: 0.7, xpMultiplier: 1.0),
        2: PoseDifficulty(baseTolerance: 15.0, requiredAccuracy: 0.8, xpMultiplier: 1.5),
        3: PoseDifficulty(baseTolerance: 10.0, requiredAccuracy: 0.9, xpMultiplier: 2.0)
    ]
    private var currentDifficulty: PoseDifficulty?
    private var userProfile: UserProfile?
    private var baselineAngles: [String: Double]?
    private var currentPose: String?

    // MARK: - Joint Weights
    private let jointWeights: [String: JointWeight] = [
        "leftHipAngle": JointWeight(name: "Left Hip", weight: 1.2, criticalThreshold: 15.0),
        "rightHipAngle": JointWeight(name: "Right Hip", weight: 1.2, criticalThreshold: 15.0),
        "leftElbowAngle": JointWeight(name: "Left Elbow", weight: 0.8, criticalThreshold: 25.0),
        "rightElbowAngle": JointWeight(name: "Right Elbow", weight: 0.8, criticalThreshold: 25.0),
        "leftKneeAngle": JointWeight(name: "Left Knee", weight: 1.0, criticalThreshold: 20.0),
        "rightKneeAngle": JointWeight(name: "Right Knee", weight: 1.0, criticalThreshold: 20.0),
        "spineAngle": JointWeight(name: "Spine", weight: 1.5, criticalThreshold: 10.0),
        "shoulderAlignment": JointWeight(name: "Shoulders", weight: 1.0, criticalThreshold: 20.0),
        "hipAlignment": JointWeight(name: "Hips", weight: 1.2, criticalThreshold: 15.0)
    ]

    // MARK: - Public Methods

    func setCurrentPose(_ pose: String) {
        currentPose = pose
        loadBaselineAngles(for: pose)
    }

    func setUserProfile(_ profile: UserProfile) {
        userProfile = profile
        updateDifficultyLevel()
    }

    func getCurrentDifficulty() -> PoseDifficulty {
        return currentDifficulty ?? difficultyLevels[1]!
    }

    func computeWeightedAccuracy(liveAngles: [String: Double], baseline: [String: Double]) -> Double {
        var weightedScore = 0.0
        var totalWeight = 0.0
        let difficulty = getCurrentDifficulty()

        for (key, liveValue) in liveAngles {
            guard let target = baseline[key], let weight = jointWeights[key] else { continue }
            let error = abs(liveValue - target)
            let adjustedTolerance = weight.criticalThreshold * (difficulty.baseTolerance / 15.0)
            let score = max(0, 100 - (error / adjustedTolerance) * 100)
            weightedScore += score * weight.weight
            totalWeight += weight.weight
        }

        let baseAccuracy = totalWeight > 0 ? weightedScore / totalWeight : 0
        return baseAccuracy >= difficulty.requiredAccuracy * 100 ? baseAccuracy : baseAccuracy * 0.8
    }

    func analyzePose(_ observation: VNHumanBodyPoseObservation) -> [PoseCorrection] {
        var corrections: [PoseCorrection] = []

        if let correction = checkStability(observation) { corrections.append(correction) }
        if let correction = checkAlignment(observation) { corrections.append(correction) }
        if let correction = checkJointAngles(observation) { corrections.append(correction) }
        if let correction = checkSymmetry(observation) { corrections.append(correction) }
        if let correction = checkPoseSpecificCorrections(observation) { corrections.append(correction) }

        return corrections
    }

    // MARK: - Private Helpers

    private func updateDifficultyLevel() {
        guard let profile = userProfile else {
            currentDifficulty = difficultyLevels[1]
            return
        }
        currentDifficulty = difficultyLevels[min(profile.level, 3)] ?? difficultyLevels[1]
    }

    private func loadBaselineAngles(for pose: String) {
        guard let url = Bundle.main.url(forResource: "\(pose)_baseline_angles", withExtension: "json") else {
            print("⚠️ Could not find baseline angles file for pose: \(pose)")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: [String: Double]].self, from: data)
            if let key = decoded.keys.first {
                baselineAngles = decoded[key]
            }
        } catch {
            print("⚠️ Error loading baseline angles: \(error)")
        }
    }

    private func checkStability(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        let avgConfidence = observation.availableJointNames.reduce(0.0) { sum, joint in
            (try? observation.recognizedPoint(joint).confidence).map(Double.init) ?? sum
        } / Double(observation.availableJointNames.count)

        if avgConfidence < stabilityThreshold {
            return PoseCorrection(
                type: .stability,
                message: "Hold the pose more steadily",
                severity: 1.0 - avgConfidence,
                affectedJoints: observation.availableJointNames
            )
        }
        return nil
    }

    private func checkAlignment(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let lShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rShoulder = try? observation.recognizedPoint(.rightShoulder),
              let lHip = try? observation.recognizedPoint(.leftHip),
              let rHip = try? observation.recognizedPoint(.rightHip) else { return nil }

        let sAlign = abs(lShoulder.location.y - rShoulder.location.y)
        let hAlign = abs(lHip.location.y - rHip.location.y)

        if sAlign > 0.1 || hAlign > 0.1 {
            return PoseCorrection(
                type: .alignment,
                message: "Keep your shoulders and hips level",
                severity: max(sAlign, hAlign),
                affectedJoints: [.leftShoulder, .rightShoulder, .leftHip, .rightHip]
            )
        }
        return nil
    }

    private func checkSymmetry(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let lShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rShoulder = try? observation.recognizedPoint(.rightShoulder),
              let lHip = try? observation.recognizedPoint(.leftHip),
              let rHip = try? observation.recognizedPoint(.rightHip) else { return nil }

        let sSym = abs(lShoulder.location.x - rShoulder.location.x)
        let hSym = abs(lHip.location.x - rHip.location.x)

        if sSym > 0.1 || hSym > 0.1 {
            return PoseCorrection(
                type: .symmetry,
                message: "Keep your body symmetrical",
                severity: max(sSym, hSym),
                affectedJoints: [.leftShoulder, .rightShoulder, .leftHip, .rightHip]
            )
        }
        return nil
    }

    private func checkPoseSpecificCorrections(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let currentPose = currentPose else { return nil }
        switch currentPose {
        case "FullRollUp": return checkFullRollUpCorrections(observation)
        default: return nil
        }
    }

    private func checkFullRollUpCorrections(_ obs: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let neck = try? obs.recognizedPoint(.neck),
              let root = try? obs.recognizedPoint(.root) else { return nil }

        let spineDeviation = abs(neck.location.x - root.location.x)
        if spineDeviation > 0.1 {
            return PoseCorrection(
                type: .alignment,
                message: "Keep your spine straight during the roll up",
                severity: spineDeviation,
                affectedJoints: [.neck, .root]
            )
        }
        return nil
    }

    private func checkJointAngles(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let baseline = baselineAngles else { return nil }

        var maxDev = 0.0
        var worstJoint: VNHumanBodyPoseObservation.JointName?

        for (jointName, targetAngle) in baseline {
            let joint = mapJointName(jointName)
            guard let angle = calculateJointAngle(observation, jointName: joint) else { continue }

            let deviation = abs(angle - targetAngle)
            if deviation > maxDev {
                maxDev = deviation
                worstJoint = joint
            }
        }

        if let worst = worstJoint, maxDev > 15.0 {
            return PoseCorrection(
                type: .angle,
                message: "Adjust your \(worst.rawValue) angle",
                severity: min(maxDev / 45.0, 1.0),
                affectedJoints: [worst]
            )
        }
        return nil
    }

    private func mapJointName(_ name: String) -> VNHumanBodyPoseObservation.JointName {
        switch name {
        case "neckAngle": return .neck
        case "leftShoulder": return .leftShoulder
        case "rightShoulder": return .rightShoulder
        case "leftElbow": return .leftElbow
        case "rightElbow": return .rightElbow
        case "leftHip": return .leftHip
        case "rightHip": return .rightHip
        case "leftKnee": return .leftKnee
        case "rightKnee": return .rightKnee
        case "leftAnkle": return .leftAnkle
        case "rightAnkle": return .rightAnkle
        case "root": return .root
        default: return .root
        }
    }

    private func calculateJointAngle(_ obs: VNHumanBodyPoseObservation, jointName: VNHumanBodyPoseObservation.JointName) -> Double? {
        guard let p = try? obs.recognizedPoint(jointName) else { return nil }

        switch jointName {
        case .neck:
            guard let ls = try? obs.recognizedPoint(.leftShoulder),
                  let rs = try? obs.recognizedPoint(.rightShoulder) else { return nil }
            return calculateAngle(point1: ls.location, point2: p.location, point3: rs.location)

        case .leftShoulder, .rightShoulder:
            guard let neck = try? obs.recognizedPoint(.neck),
                  let elbow = try? obs.recognizedPoint(jointName == .leftShoulder ? .leftElbow : .rightElbow) else { return nil }
            return calculateAngle(point1: neck.location, point2: p.location, point3: elbow.location)

        case .leftElbow, .rightElbow:
            guard let shoulder = try? obs.recognizedPoint(jointName == .leftElbow ? .leftShoulder : .rightShoulder),
                  let wrist = try? obs.recognizedPoint(jointName == .leftElbow ? .leftWrist : .rightWrist) else { return nil }
            return calculateAngle(point1: shoulder.location, point2: p.location, point3: wrist.location)

        case .leftHip, .rightHip:
            guard let root = try? obs.recognizedPoint(.root),
                  let knee = try? obs.recognizedPoint(jointName == .leftHip ? .leftKnee : .rightKnee) else { return nil }
            return calculateAngle(point1: root.location, point2: p.location, point3: knee.location)

        case .leftKnee, .rightKnee:
            guard let hip = try? obs.recognizedPoint(jointName == .leftKnee ? .leftHip : .rightHip),
                  let ankle = try? obs.recognizedPoint(jointName == .leftKnee ? .leftAnkle : .rightAnkle) else { return nil }
            return calculateAngle(point1: hip.location, point2: p.location, point3: ankle.location)

        default:
            return nil
        }
    }

    private func calculateAngle(point1: CGPoint, point2: CGPoint, point3: CGPoint) -> Double {
        let v1 = CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
        let v2 = CGPoint(x: point3.x - point2.x, y: point3.y - point2.y)

        let dot = v1.x * v2.x + v1.y * v2.y
        let mag = hypot(v1.x, v1.y) * hypot(v2.x, v2.y)
        let cos = dot / mag
        return Darwin.acos(max(min(cos, 1), -1)) * 180.0 / Double.pi


    }
}


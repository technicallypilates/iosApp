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
    private let jointTolerance: Double = 15.0 // Degrees of tolerance for joint angles
    private let stabilityThreshold: Double = 0.8 // Minimum confidence for stable pose
    private let difficultyLevels: [Int: PoseDifficulty] = [
        1: PoseDifficulty(baseTolerance: 20.0, requiredAccuracy: 0.7, xpMultiplier: 1.0),
        2: PoseDifficulty(baseTolerance: 15.0, requiredAccuracy: 0.8, xpMultiplier: 1.5),
        3: PoseDifficulty(baseTolerance: 10.0, requiredAccuracy: 0.9, xpMultiplier: 2.0)
    ]
    private var currentDifficulty: PoseDifficulty?
    private var userProfile: UserProfile?
    // MARK: - Joint Weights
    private let jointWeights: [String: JointWeight] = [
        "spineAngle": JointWeight(name: "Spine", weight: 1.5, criticalThreshold: 10.0),
        "hipAlignment": JointWeight(name: "Hips", weight: 1.2, criticalThreshold: 15.0),
        "shoulderAlignment": JointWeight(name: "Shoulders", weight: 1.0, criticalThreshold: 20.0),
        "leftHipAngle": JointWeight(name: "Left Hip", weight: 1.2, criticalThreshold: 15.0),
        "rightHipAngle": JointWeight(name: "Right Hip", weight: 1.2, criticalThreshold: 15.0),
        "leftKneeAngle": JointWeight(name: "Left Knee", weight: 1.0, criticalThreshold: 20.0),
        "rightKneeAngle": JointWeight(name: "Right Knee", weight: 1.0, criticalThreshold: 20.0),
        "leftElbowAngle": JointWeight(name: "Left Elbow", weight: 0.8, criticalThreshold: 25.0),
        "rightElbowAngle": JointWeight(name: "Right Elbow", weight: 0.8, criticalThreshold: 25.0),
        "neckAngle": JointWeight(name: "Neck", weight: 1.3, criticalThreshold: 12.0),
        "velocityX": JointWeight(name: "Velocity X", weight: 0.7, criticalThreshold: 0.3),
        "velocityY": JointWeight(name: "Velocity Y", weight: 0.7, criticalThreshold: 0.3),
        "velocityZ": JointWeight(name: "Velocity Z", weight: 0.7, criticalThreshold: 0.3)
    ]
    
    // MARK: - Correction Types
    enum CorrectionType {
        case alignment
        case angle
        case stability
        case symmetry
    }
    private var baselineAngles: [String: Double]?
    private var currentPose: String?
   
    // MARK: - Public Methods
    func setCurrentPose(_ pose: String) {
        currentPose = pose
        loadBaselineAngles(for: pose)
    }

    func analyzePose(_ observation: VNHumanBodyPoseObservation) -> [PoseCorrection] {
        var corrections: [PoseCorrection] = []

        if let stabilityCorrection = checkStability(observation) {
            corrections.append(stabilityCorrection)
        }

        if let alignmentCorrection = checkAlignment(observation) {
            corrections.append(alignmentCorrection)
        }

        if let angleCorrection = checkJointAngles(observation) {
            corrections.append(angleCorrection)
        }

        if let symmetryCorrection = checkSymmetry(observation) {
            corrections.append(symmetryCorrection)
        }

        if let poseSpecificCorrection = checkPoseSpecificCorrections(observation) {
            corrections.append(poseSpecificCorrection)
        }

        return corrections
    }

    func setUserProfile(_ profile: UserProfile) {
        userProfile = profile
        updateDifficultyLevel()
    }

    private func updateDifficultyLevel() {
        guard let profile = userProfile else {
            currentDifficulty = difficultyLevels[1]
            return
        }
        currentDifficulty = difficultyLevels[min(profile.level, 3)] ?? difficultyLevels[1]
    }

    func getCurrentDifficulty() -> PoseDifficulty {
        return currentDifficulty ?? difficultyLevels[1]!
    }

    func computeWeightedAccuracy(liveAngles: [String: Double], baseline: [String: Double]) -> Double {
        var weightedScore = 0.0
        var totalWeight = 0.0

        let difficulty = getCurrentDifficulty()

        for (key, liveValue) in liveAngles {
            if let target = baseline[key],
               let weight = jointWeights[key] {
                let error = abs(liveValue - target)
                let adjustedTolerance = weight.criticalThreshold * (difficulty.baseTolerance / 15.0)
                let score = max(0, 100 - (error / adjustedTolerance) * 100)
                weightedScore += score * weight.weight
                totalWeight += weight.weight
            }
        }

        let baseAccuracy = totalWeight > 0 ? weightedScore / totalWeight : 0
        return baseAccuracy >= difficulty.requiredAccuracy * 100 ? baseAccuracy : baseAccuracy * 0.8
    }

    private func loadBaselineAngles(for pose: String) {
        guard let url = Bundle.main.url(forResource: "\(pose)_baseline_angles", withExtension: "json") else {
            print("Could not find baseline angles file for pose: \(pose)")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: [String: Double]].self, from: data)
        } catch {
            print("Error loading baseline angles: \(error)")
        }
    }

    private func checkStability(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        let averageConfidence = observation.availableJointNames.reduce(0.0) { sum, joint in
            guard let point = try? observation.recognizedPoint(joint) else { return sum }
            return sum + Double(point.confidence)
        } / Double(observation.availableJointNames.count)

        if averageConfidence < 0.7 {
            return PoseCorrection(
                type: .stability,
                message: "Hold the pose more steadily",
                severity: 1.0 - Double(averageConfidence),
                affectedJoints: observation.availableJointNames
            )
        }
        return nil
    }

    private func checkAlignment(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
              let leftHip = try? observation.recognizedPoint(.leftHip),
              let rightHip = try? observation.recognizedPoint(.rightHip) else {
            return nil
        }

        let shoulderAlignment = abs(leftShoulder.location.y - rightShoulder.location.y)
        let hipAlignment = abs(leftHip.location.y - rightHip.location.y)

        if shoulderAlignment > 0.1 || hipAlignment > 0.1 {
            return PoseCorrection(
                type: .alignment,
                message: "Keep your shoulders and hips level",
                severity: max(shoulderAlignment, hipAlignment),
                affectedJoints: [.leftShoulder, .rightShoulder, .leftHip, .rightHip]
            )
        }
        return nil
    }

    private func checkJointAngles(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let baselineAngles = baselineAngles else { return nil }

        var maxDeviation = 0.0
        var worstJoint: VNHumanBodyPoseObservation.JointName?

        for (jointName, targetAngle) in baselineAngles {
            let joint: VNHumanBodyPoseObservation.JointName
            switch jointName {
            case "neck": joint = .neck
            case "leftShoulder": joint = .leftShoulder
            case "rightShoulder": joint = .rightShoulder
            case "leftElbow": joint = .leftElbow
            case "rightElbow": joint = .rightElbow
            case "leftWrist": joint = .leftWrist
            case "rightWrist": joint = .rightWrist
            case "leftHip": joint = .leftHip
            case "rightHip": joint = .rightHip
            case "leftKnee": joint = .leftKnee
            case "rightKnee": joint = .rightKnee
            case "leftAnkle": joint = .leftAnkle
            case "rightAnkle": joint = .rightAnkle
            case "root": joint = .root
            default: continue
            }

            guard let currentAngle = calculateJointAngle(observation, jointName: joint) else { continue }

            let deviation = abs(currentAngle - targetAngle)
            if deviation > maxDeviation {
                maxDeviation = deviation
                worstJoint = joint
            }
        }

        if let worstJoint = worstJoint, maxDeviation > 15.0 {
            return PoseCorrection(
                type: .angle,
                message: "Adjust your \(worstJoint.rawValue) angle",
                severity: min(maxDeviation / 45.0, 1.0),
                affectedJoints: [worstJoint]
            )
        }
        return nil
    }

    private func checkSymmetry(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
              let leftHip = try? observation.recognizedPoint(.leftHip),
              let rightHip = try? observation.recognizedPoint(.rightHip) else {
            return nil
        }

        let shoulderSymmetry = abs(leftShoulder.location.x - rightShoulder.location.x)
        let hipSymmetry = abs(leftHip.location.x - rightHip.location.x)

        if shoulderSymmetry > 0.1 || hipSymmetry > 0.1 {
            return PoseCorrection(
                type: .symmetry,
                message: "Keep your body symmetrical",
                severity: max(shoulderSymmetry, hipSymmetry),
                affectedJoints: [.leftShoulder, .rightShoulder, .leftHip, .rightHip]
            )
        }
        return nil
    }

    private func checkPoseSpecificCorrections(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let currentPose = currentPose else { return nil }

        switch currentPose {
        case "FullRollUp":
            return checkFullRollUpCorrections(observation)
        default:
            return nil
        }
    }

    private func checkFullRollUpCorrections(_ observation: VNHumanBodyPoseObservation) -> PoseCorrection? {
        guard let neck = try? observation.recognizedPoint(.neck),
              let root = try? observation.recognizedPoint(.root) else {
            return nil
        }

        let spineAlignment = abs(neck.location.x - root.location.x)
        if spineAlignment > 0.1 {
            return PoseCorrection(
                type: .alignment,
                message: "Keep your spine straight during the roll up",
                severity: spineAlignment,
                affectedJoints: [.neck, .root]
            )
        }
        return nil
    }

    private func calculateJointAngle(_ observation: VNHumanBodyPoseObservation, jointName: VNHumanBodyPoseObservation.JointName) -> Double? {
        guard let point = try? observation.recognizedPoint(jointName) else { return nil }

        switch jointName {
        case .neck:
            guard let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
                  let rightShoulder = try? observation.recognizedPoint(.rightShoulder) else {
                return nil
            }
            return calculateAngle(point1: leftShoulder.location, point2: point.location, point3: rightShoulder.location)

        case .leftShoulder, .rightShoulder:
            guard let neck = try? observation.recognizedPoint(.neck),
                  let elbow = try? observation.recognizedPoint(jointName == .leftShoulder ? .leftElbow : .rightElbow) else {
                return nil
            }
            return calculateAngle(point1: neck.location, point2: point.location, point3: elbow.location)

        case .leftElbow, .rightElbow:
            guard let shoulder = try? observation.recognizedPoint(jointName == .leftElbow ? .leftShoulder : .rightShoulder),
                  let wrist = try? observation.recognizedPoint(jointName == .leftElbow ? .leftWrist : .rightWrist) else {
                return nil
            }
            return calculateAngle(point1: shoulder.location, point2: point.location, point3: wrist.location)

        case .leftHip, .rightHip:
            guard let root = try? observation.recognizedPoint(.root),
                  let knee = try? observation.recognizedPoint(jointName == .leftHip ? .leftKnee : .rightKnee) else {
                return nil
            }
            return calculateAngle(point1: root.location, point2: point.location, point3: knee.location)

        case .leftKnee, .rightKnee:
            guard let hip = try? observation.recognizedPoint(jointName == .leftKnee ? .leftHip : .rightHip),
                  let ankle = try? observation.recognizedPoint(jointName == .leftKnee ? .leftAnkle : .rightAnkle) else {
                return nil
            }
            return calculateAngle(point1: hip.location, point2: point.location, point3: ankle.location)

        default:
            return nil
        }
    }

    private func calculateAngle(point1: CGPoint, point2: CGPoint, point3: CGPoint) -> Double {
        let v1 = CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
        let v2 = CGPoint(x: point3.x - point2.x, y: point3.y - point2.y)

        let dot = v1.x * v2.x + v1.y * v2.y
        let v1mag = sqrt(v1.x * v1.x + v1.y * v1.y)
        let v2mag = sqrt(v2.x * v2.x + v2.y * v2.y)

        let cos = dot / (v1mag * v2mag)
        let angle = acos(cos) * 180.0 / .pi

        return angle
    }
}



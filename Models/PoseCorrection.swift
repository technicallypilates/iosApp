import Foundation
import Vision

struct PoseCorrection: Identifiable, Equatable {
    let id = UUID()
    let type: CorrectionType
    let message: String
    let severity: Double
    let affectedJoints: [VNHumanBodyPoseObservation.JointName]
    
    enum CorrectionType: Equatable {
        case alignment
        case angle
        case stability
        case symmetry
    }
    
    init(type: CorrectionType, message: String, severity: Double, affectedJoints: [VNHumanBodyPoseObservation.JointName]) {
        self.type = type
        self.message = message
        self.severity = severity
        self.affectedJoints = affectedJoints
    }
    
    static func == (lhs: PoseCorrection, rhs: PoseCorrection) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.message == rhs.message &&
               lhs.severity == rhs.severity &&
               lhs.affectedJoints == rhs.affectedJoints
    }
} 
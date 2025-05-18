import Foundation

struct JointWeight: Codable {
    let name: String
    let weight: Double
    let criticalThreshold: Double
    
    init(name: String, weight: Double, criticalThreshold: Double) {
        self.name = name
        self.weight = weight
        self.criticalThreshold = criticalThreshold
    }
} 
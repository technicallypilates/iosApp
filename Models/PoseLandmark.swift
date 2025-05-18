import Foundation
import CoreGraphics

struct PoseLandmark: Codable {
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
    let visibility: CGFloat
    let name: String
    
    init(x: CGFloat, y: CGFloat, z: CGFloat, visibility: CGFloat, name: String) {
        self.x = x
        self.y = y
        self.z = z
        self.visibility = visibility
        self.name = name
    }
    
    var point: CGPoint {
        CGPoint(x: x, y: y)
    }
    
    var isVisible: Bool {
        visibility > 0.5
    }
}

struct PoseLandmarks: Codable {
    let landmarks: [PoseLandmark]
    let timestamp: Date
    
    init(landmarks: [PoseLandmark], timestamp: Date = Date()) {
        self.landmarks = landmarks
        self.timestamp = timestamp
    }
    
    func getLandmark(named name: String) -> PoseLandmark? {
        landmarks.first { $0.name == name }
    }
    
    func calculateAngle(landmark1: String, landmark2: String, landmark3: String) -> CGFloat? {
        guard let p1 = getLandmark(named: landmark1),
              let p2 = getLandmark(named: landmark2),
              let p3 = getLandmark(named: landmark3) else {
            return nil
        }
        
        let v1 = CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
        let v2 = CGPoint(x: p3.x - p2.x, y: p3.y - p2.y)
        
        let dot = v1.x * v2.x + v1.y * v2.y
        let v1mag = sqrt(v1.x * v1.x + v1.y * v1.y)
        let v2mag = sqrt(v2.x * v2.x + v2.y * v2.y)
        
        let cos = dot / (v1mag * v2mag)
        let angle = acos(cos) * 180 / .pi
        
        return angle
    }
    
    func calculateDistance(landmark1: String, landmark2: String) -> CGFloat? {
        guard let p1 = getLandmark(named: landmark1),
              let p2 = getLandmark(named: landmark2) else {
            return nil
        }
        
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
} 
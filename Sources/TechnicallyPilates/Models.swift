import Foundation

struct Pose: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var description: String
    var category: String
    var difficulty: Int
    var imageURL: String?
    var videoURL: String?
    var instructions: [String]
    var benefits: [String]
    var modifications: [String]
    var contraindications: [String]
    var duration: TimeInterval
    var repetitions: Int
    
    init(id: UUID = UUID(), name: String, description: String, category: String, difficulty: Int, imageURL: String? = nil, videoURL: String? = nil, instructions: [String], benefits: [String], modifications: [String], contraindications: [String], duration: TimeInterval, repetitions: Int) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.instructions = instructions
        self.benefits = benefits
        self.modifications = modifications
        self.contraindications = contraindications
        self.duration = duration
        self.repetitions = repetitions
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Pose, rhs: Pose) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PoseLogEntry: Identifiable, Codable {
    let id: UUID
    let poseId: UUID
    let routineId: UUID
    let date: Date
    let repsCompleted: Int
    var repetitions: Int
    var timestamp: Date
    
    init(id: UUID = UUID(), poseId: UUID, routineId: UUID, date: Date = Date(), repsCompleted: Int, repetitions: Int = 0, timestamp: Date = Date()) {
        self.id = id
        self.poseId = poseId
        self.routineId = routineId
        self.date = date
        self.repsCompleted = repsCompleted
        self.repetitions = repetitions
        self.timestamp = timestamp
    }
}

struct Routine: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var category: String
    var poses: [Pose]
    var duration: TimeInterval
    var difficulty: Int
    var isFavorite: Bool
    
    init(id: UUID = UUID(), name: String, description: String, category: String, poses: [Pose], duration: TimeInterval, difficulty: Int, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.poses = poses
        self.duration = duration
        self.difficulty = difficulty
        self.isFavorite = isFavorite
    }
}

struct Achievement: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var imageURL: String?
    var xpReward: Int
    var isUnlocked: Bool
    
    init(id: UUID = UUID(), name: String, description: String, imageURL: String? = nil, xpReward: Int, isUnlocked: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.xpReward = xpReward
        self.isUnlocked = isUnlocked
    }
}

struct UserProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var email: String
    var goals: [String]
    var xp: Int
    var level: Int
    var streakCount: Int
    var lastActiveDate: Date
    var unlockedAchievements: [Achievement]
    var unlockedRoutines: [Routine]
    
    init(id: UUID = UUID(), name: String, email: String, goals: [String] = [], xp: Int = 0, level: Int = 1, streakCount: Int = 0, lastActiveDate: Date = Date(), unlockedAchievements: [Achievement] = [], unlockedRoutines: [Routine] = []) {
        self.id = id
        self.name = name
        self.email = email
        self.goals = goals
        self.xp = xp
        self.level = level
        self.streakCount = streakCount
        self.lastActiveDate = lastActiveDate
        self.unlockedAchievements = unlockedAchievements
        self.unlockedRoutines = unlockedRoutines
    }
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.id == rhs.id
    }
    
    mutating func updateProgress(newEntries: [PoseLogEntry]) {
        // Update XP based on completed poses
        for entry in newEntries {
            // Note: This assumes we have access to the pose's difficulty
            // In a real app, we'd need to look up the pose by ID
            xp += entry.repsCompleted * 10 // Default XP per rep
        }
        
        // Update level based on XP
        level = Int(sqrt(Double(xp) / 100)) + 1
        
        // Update streak
        let calendar = Calendar.current
        if let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDate, to: Date()).day {
            if daysSinceLastActive == 1 {
                streakCount += 1
            } else if daysSinceLastActive > 1 {
                streakCount = 1
            }
        }
        lastActiveDate = Date()
    }
} 

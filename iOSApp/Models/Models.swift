import Foundation
import FirebaseFirestore

// MARK: - PoseLogEntry

struct PoseLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let poseId: UUID
    let routineId: UUID
    let repsCompleted: Int
    let accuracyScore: Int
    let timestamp: Date

    init(
        poseId: UUID,
        routineId: UUID,
        repsCompleted: Int,
        accuracyScore: Int,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.poseId = poseId
        self.routineId = routineId
        self.repsCompleted = repsCompleted
        self.accuracyScore = accuracyScore
        self.timestamp = timestamp
    }

    var dictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "poseId": poseId.uuidString,
            "routineId": routineId.uuidString,
            "repsCompleted": repsCompleted,
            "accuracyScore": accuracyScore,
            "timestamp": timestamp
        ]
    }
}

// MARK: - Pose

struct Pose: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var category: String
    var difficulty: Int
    var instructions: [String]
    var benefits: [String]
    var modifications: [String]
    var contraindications: [String]
    var duration: Double
    var repetitions: Int
    var xpReward: Int
    var isUnlocked: Bool
    var unlockAccuracy: Double?
    var requiredAchievement: String?

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: String,
        difficulty: Int,
        instructions: [String] = [],
        benefits: [String] = [],
        modifications: [String] = [],
        contraindications: [String] = [],
        duration: Double,
        repetitions: Int,
        xpReward: Int = 10,
        isUnlocked: Bool = true,
        unlockAccuracy: Double? = nil,
        requiredAchievement: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.instructions = instructions
        self.benefits = benefits
        self.modifications = modifications
        self.contraindications = contraindications
        self.duration = duration
        self.repetitions = repetitions
        self.xpReward = xpReward
        self.isUnlocked = isUnlocked
        self.unlockAccuracy = unlockAccuracy
        self.requiredAchievement = requiredAchievement
    }
}

// MARK: - Routine

struct Routine: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var category: String
    var poses: [Pose]
    var duration: TimeInterval
    var difficulty: Int
    var isFavorite: Bool
    var unlockAccuracy: Double?
    var isUnlocked: Bool
    var xpReward: Int
    var progress: Double?
    var unlockType: UnlockType
    var requiredAchievement: String?

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: String,
        poses: [Pose],
        duration: TimeInterval,
        difficulty: Int,
        isFavorite: Bool = false,
        unlockAccuracy: Double? = nil,
        isUnlocked: Bool = true,
        xpReward: Int = 50,
        progress: Double? = nil,
        unlockType: UnlockType = .none,
        requiredAchievement: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.poses = poses
        self.duration = duration
        self.difficulty = difficulty
        self.isFavorite = isFavorite
        self.unlockAccuracy = unlockAccuracy
        self.isUnlocked = isUnlocked
        self.xpReward = xpReward
        self.progress = progress
        self.unlockType = unlockType
        self.requiredAchievement = requiredAchievement
    }

    init(from dictionary: [String: Any]) throws {
        guard let name = dictionary["name"] as? String,
              let description = dictionary["description"] as? String,
              let category = dictionary["category"] as? String,
              let duration = dictionary["duration"] as? TimeInterval,
              let difficulty = dictionary["difficulty"] as? Int else {
            throw NSError(domain: "Routine", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid routine data"])
        }
        self.id = UUID()
        self.name = name
        self.description = description
        self.category = category
        self.poses = [] // You could deserialize poses here if needed
        self.duration = duration
        self.difficulty = difficulty
        self.isFavorite = false
        self.unlockAccuracy = dictionary["unlockAccuracy"] as? Double
        self.isUnlocked = dictionary["isUnlocked"] as? Bool ?? true
        self.xpReward = dictionary["xpReward"] as? Int ?? 50
        self.progress = dictionary["progress"] as? Double
        self.unlockType = UnlockType(rawValue: (dictionary["unlockType"] as? String) ?? "none") ?? .none
        self.requiredAchievement = dictionary["requiredAchievement"] as? String
    }

    var dictionary: [String: Any]? {
        return [
            "id": id.uuidString,
            "name": name,
            "description": description,
            "category": category,
            "duration": duration,
            "difficulty": difficulty,
            "unlockAccuracy": unlockAccuracy as Any,
            "isUnlocked": isUnlocked,
            "xpReward": xpReward
        ]
    }

    enum UnlockType: String, Codable {
        case none, xp, accuracy, achievement
    }
}

// MARK: - Achievement

struct Achievement: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var xpReward: Int
    var isUnlocked: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        xpReward: Int = 100,
        isUnlocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.xpReward = xpReward
        self.isUnlocked = isUnlocked
    }

    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let description = dictionary["description"] as? String else {
            return nil
        }
        self.id = UUID()
        self.name = name
        self.description = description
        self.xpReward = dictionary["xpReward"] as? Int ?? 100
        self.isUnlocked = dictionary["isUnlocked"] as? Bool ?? false
    }

    var dictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "description": description,
            "xpReward": xpReward,
            "isUnlocked": isUnlocked
        ]
    }
}

// MARK: - Goal

struct Goal: Identifiable, Codable, Hashable {
    let id: UUID
    var description: String
    var target: Int
    var progress: Int
    var dueDate: Date
    var isCompleted: Bool { progress >= target }

    var title: String { description }

    init(id: UUID = UUID(), description: String, target: Int, progress: Int = 0, dueDate: Date) {
        self.id = id
        self.description = description
        self.target = target
        self.progress = progress
        self.dueDate = dueDate
    }

    var dictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "description": description,
            "target": target,
            "progress": progress,
            "dueDate": Timestamp(date: dueDate)
        ]
    }
}

// MARK: - UserProfile

struct UserProfile: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var email: String
    var level: Int
    var xp: Int
    var streakCount: Int
    var profileImageData: Data?
    var lastActiveDate: Date
    var achievements: [Achievement]
    var unlockedRoutines: [UUID]
    var unlockedAchievements: [UUID]
    var bestStreak: Int
    var goals: [Goal]

    enum CodingKeys: String, CodingKey {
        case id, name, email, level, xp, streakCount, lastActiveDate
        case achievements, unlockedRoutines, unlockedAchievements, bestStreak, goals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        level = try container.decode(Int.self, forKey: .level)
        xp = try container.decode(Int.self, forKey: .xp)
        streakCount = try container.decode(Int.self, forKey: .streakCount)
        lastActiveDate = try container.decode(Date.self, forKey: .lastActiveDate)
        achievements = try container.decode([Achievement].self, forKey: .achievements)
        unlockedRoutines = try container.decode([UUID].self, forKey: .unlockedRoutines)
        unlockedAchievements = try container.decode([UUID].self, forKey: .unlockedAchievements)
        bestStreak = try container.decode(Int.self, forKey: .bestStreak)
        goals = try container.decode([Goal].self, forKey: .goals)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(level, forKey: .level)
        try container.encode(xp, forKey: .xp)
        try container.encode(streakCount, forKey: .streakCount)
        try container.encode(lastActiveDate, forKey: .lastActiveDate)
        try container.encode(achievements, forKey: .achievements)
        try container.encode(unlockedRoutines, forKey: .unlockedRoutines)
        try container.encode(unlockedAchievements, forKey: .unlockedAchievements)
        try container.encode(bestStreak, forKey: .bestStreak)
        try container.encode(goals, forKey: .goals)
    }

    init(
        id: String,
        name: String,
        email: String,
        level: Int = 1,
        xp: Int = 0,
        streakCount: Int = 0,
        lastActiveDate: Date = Date(),
        achievements: [Achievement] = [],
        unlockedRoutines: [UUID] = [],
        unlockedAchievements: [UUID] = [],
        bestStreak: Int = 0,
        goals: [Goal] = []
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.level = level
        self.xp = xp
        self.streakCount = streakCount
        self.lastActiveDate = lastActiveDate
        self.achievements = achievements
        self.unlockedRoutines = unlockedRoutines
        self.unlockedAchievements = unlockedAchievements
        self.bestStreak = bestStreak
        self.goals = goals
    }

    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let email = dictionary["email"] as? String,
              let level = dictionary["level"] as? Int,
              let xp = dictionary["xp"] as? Int,
              let streakCount = dictionary["streakCount"] as? Int,
              let lastActiveDate = (dictionary["lastActiveDate"] as? Timestamp)?.dateValue() else {
            return nil
        }

        self.id = id
        self.name = name
        self.email = email
        self.level = level
        self.xp = xp
        self.streakCount = streakCount
        self.lastActiveDate = lastActiveDate
        
        // Initialize achievements
        if let achievementsData = dictionary["achievements"] as? [[String: Any]] {
            self.achievements = achievementsData.compactMap { Achievement(dictionary: $0) }
        } else {
            self.achievements = []
        }

        // Initialize unlockedRoutines
        if let unlockedRoutinesData = dictionary["unlockedRoutines"] as? [String] {
            self.unlockedRoutines = unlockedRoutinesData.compactMap { UUID(uuidString: $0) }
        } else {
            self.unlockedRoutines = []
        }

        // Initialize unlockedAchievements
        if let unlockedAchievementsData = dictionary["unlockedAchievements"] as? [String] {
            self.unlockedAchievements = unlockedAchievementsData.compactMap { UUID(uuidString: $0) }
        } else {
            self.unlockedAchievements = []
        }

        // Initialize bestStreak
        self.bestStreak = dictionary["bestStreak"] as? Int ?? 0

        // Initialize goals
        if let goalsData = dictionary["goals"] as? [[String: Any]] {
            self.goals = goalsData.compactMap { goalDict -> Goal? in
                guard let id = goalDict["id"] as? UUID,
                      let description = goalDict["description"] as? String,
                      let target = goalDict["target"] as? Int,
                      let progress = goalDict["progress"] as? Int,
                      let dueDate = (goalDict["dueDate"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                return Goal(id: id, description: description, target: target, progress: progress, dueDate: dueDate)
            }
        } else {
            self.goals = []
        }
    }

    var dictionary: [String: Any]? {
        return [
            "id": id,
            "name": name,
            "email": email,
            "level": level,
            "xp": xp,
            "streakCount": streakCount,
            "lastActiveDate": Timestamp(date: lastActiveDate),
            "achievements": achievements.map { $0.dictionary },
            "unlockedRoutines": unlockedRoutines.map { $0.uuidString },
            "unlockedAchievements": unlockedAchievements.map { $0.uuidString },
            "bestStreak": bestStreak,
            "goals": goals.map { $0.dictionary }
        ]
    }

    mutating func updateProgress(with newEntries: [PoseLogEntry]) {
        for entry in newEntries {
            let accuracyFactor = Double(entry.accuracyScore) / 100.0
            xp += Int(Double(entry.repsCompleted) * 10.0 * accuracyFactor)
        }

        level = Int(sqrt(Double(xp) / 100.0)) + 1

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

// MARK: - AppState

struct AppState: Codable {
    var lastActiveDate: Date
    var currentWorkoutId: UUID?
    var lastCompletedWorkoutId: UUID?
    var streakCount: Int
    var totalWorkouts: Int
    var currentRoutineId: UUID?
    var lastSyncDate: Date?
    var pendingOperations: [String: String]?
}

// MARK: - LeaderboardEntry

struct LeaderboardEntry: Identifiable, Codable {
    let id: UUID
    let userId: String
    let userName: String
    let score: Int
    
    init(id: UUID = UUID(), userId: String, userName: String, score: Int) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.score = score
    }
    
    init?(dictionary: [String: Any]) {
        guard let userId = dictionary["userId"] as? String,
              let userName = dictionary["userName"] as? String,
              let score = dictionary["score"] as? Int else {
            return nil
        }
        self.id = UUID()
        self.userId = userId
        self.userName = userName
        self.score = score
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "userName": userName,
            "score": score
        ]
    }
}

// MARK: - Challenge

struct Challenge: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    // Add more fields as needed
    
    init(id: UUID = UUID(), title: String, description: String) {
        self.id = id
        self.title = title
        self.description = description
    }
}


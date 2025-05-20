import Foundation
import FirebaseFirestore
import Vision

// MARK: - PoseLogEntry

struct PoseLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let poseId: UUID
    let routineId: UUID
    let repsCompleted: Int
    let accuracyScore: Int
    let timestamp: Date
    var jointAccuracies: [String: Double]
    var features: [String: Double]  // ✅ New field for 9 input features

    init(
        poseId: UUID,
        routineId: UUID,
        repsCompleted: Int,
        accuracyScore: Int,
        timestamp: Date = Date(),
        jointAccuracies: [String: Double] = [:],
        features: [String: Double] = [:]
    ) {
        self.id = UUID()
        self.poseId = poseId
        self.routineId = routineId
        self.repsCompleted = repsCompleted
        self.accuracyScore = accuracyScore
        self.timestamp = timestamp
        self.jointAccuracies = jointAccuracies
        self.features = features
    }

    var dictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "poseId": poseId.uuidString,
            "routineId": routineId.uuidString,
            "repsCompleted": repsCompleted,
            "accuracyScore": accuracyScore,
            "timestamp": timestamp,
            "jointAccuracies": jointAccuracies,
            "features": features
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
    var targetAngles: [String: Double]?

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
        requiredAchievement: String? = nil,
        targetAngles: [String: Double]? = nil
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
        self.targetAngles = targetAngles
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
    var requirements: AchievementRequirements
    var xpReward: Int
    var isUnlocked: Bool = false

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        requirements: AchievementRequirements,
        xpReward: Int = 100,
        isUnlocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.requirements = requirements
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
        self.requirements = AchievementRequirements(
            minAccuracy: dictionary["minAccuracy"] as? Double ?? 0.0,
            minConsistency: dictionary["minConsistency"] as? Double ?? 0.0,
            minStreak: dictionary["minStreak"] as? Int ?? 0,
            requiredPoses: dictionary["requiredPoses"] as? [String] ?? []
        )
    }

    var dictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "description": description,
            "xpReward": xpReward,
            "isUnlocked": isUnlocked,
            "minAccuracy": requirements.minAccuracy,
            "minConsistency": requirements.minConsistency,
            "minStreak": requirements.minStreak,
            "requiredPoses": requirements.requiredPoses
        ]
    }
    
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.requirements == rhs.requirements &&
        lhs.xpReward == rhs.xpReward &&
        lhs.isUnlocked == rhs.isUnlocked
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(requirements)
        hasher.combine(xpReward)
        hasher.combine(isUnlocked)
    }
}

struct AchievementRequirements: Codable, Equatable, Hashable {
    let minAccuracy: Double
    let minConsistency: Double
    let minStreak: Int
    let requiredPoses: [String]
    
    func isMet(by metrics: ExerciseMetrics) -> Bool {
        return metrics.accuracy >= minAccuracy &&
               metrics.consistency >= minConsistency &&
               metrics.streak >= minStreak &&
               (requiredPoses.isEmpty || requiredPoses.allSatisfy { pose in metrics.completedPoses.contains(pose) })
    }
    
    static func == (lhs: AchievementRequirements, rhs: AchievementRequirements) -> Bool {
        lhs.minAccuracy == rhs.minAccuracy &&
        lhs.minConsistency == rhs.minConsistency &&
        lhs.minStreak == rhs.minStreak &&
        lhs.requiredPoses == rhs.requiredPoses
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(minAccuracy)
        hasher.combine(minConsistency)
        hasher.combine(minStreak)
        hasher.combine(requiredPoses)
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

class UserProfile: ObservableObject, Identifiable, Codable, Equatable, Hashable {
    let id: String
    @Published var name: String
    @Published var email: String
    @Published var level: Int
    @Published var xp: Int
    @Published var streakCount: Int
    @Published var profileImageData: Data?
    @Published var lastActiveDate: Date
    @Published var achievements: [Achievement]
    @Published var unlockedRoutines: [UUID]
    @Published var unlockedAchievements: [UUID]
    @Published var bestStreak: Int
    @Published var goals: [Goal]

    enum CodingKeys: String, CodingKey {
        case id, name, email, level, xp, streakCount, lastActiveDate
        case achievements, unlockedRoutines, unlockedAchievements, bestStreak, goals
    }

    required init(from decoder: Decoder) throws {
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

    private var baseXP: Double { 10.0 }
    private var consistencyBonus: Double { 1.5 }
    private var streakMultiplier: Double { 1.2 }

    func calculateXP(for metrics: ExerciseMetrics) -> Int {
        var xp = baseXP * metrics.accuracy
        if metrics.consistency > 0.8 {
            xp *= consistencyBonus
        }
        if metrics.streak > 0 {
            xp *= pow(streakMultiplier, Double(metrics.streak))
        }
        xp *= Double(metrics.difficulty)
        return Int(xp)
    }

    func updateProgress(with newEntries: [PoseLogEntry]) {
        let metrics = calculateExerciseMetrics(from: newEntries)
        let xp = calculateXP(for: metrics)
        self.xp += xp
        updateStreaks(metrics)
        checkAchievements(metrics)
    }

    func calculateExerciseMetrics(from entries: [PoseLogEntry], jointWeights: [JointWeight] = []) -> ExerciseMetrics {
        guard !entries.isEmpty else {
            return ExerciseMetrics(accuracy: 0, consistency: 0, duration: 0, difficulty: 1, streak: 0, completedPoses: [])
        }
        // Weighted accuracy if joint weights and jointAccuracies are present
        let accuracy: Double
        if !jointWeights.isEmpty && entries.contains(where: { !$0.jointAccuracies.isEmpty }) {
            accuracy = weightedAccuracy(from: entries, jointWeights: jointWeights)
        } else {
            accuracy = entries.map { Double($0.accuracyScore) / 100.0 }.reduce(0, +) / Double(entries.count)
        }
        // Consistency: percent of entries above 80% accuracy
        let highAccuracies = entries.filter { Double($0.accuracyScore) / 100.0 > 0.8 }.count
        let consistency = Double(highAccuracies) / Double(entries.count)
        // Duration: time span between first and last entry
        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        let duration = sorted.last!.timestamp.timeIntervalSince(sorted.first!.timestamp)
        // Difficulty: average from poses if available (fallback to 1)
        let poseDifficulties = entries.compactMap { entry in
            1 // You may want to pass in a pose lookup dictionary for real data
        }
        let difficulty = poseDifficulties.isEmpty ? 1 : Int(Double(poseDifficulties.reduce(0, +)) / Double(poseDifficulties.count))
        // Streak: max consecutive days with entries
        let calendar = Calendar.current
        let days = Set(entries.map { calendar.startOfDay(for: $0.timestamp) })
        let sortedDays = days.sorted()
        var maxStreak = 1, currentStreak = 1
        for i in 1..<sortedDays.count {
            let prev = sortedDays[i-1]
            let curr = sortedDays[i]
            if calendar.dateComponents([.day], from: prev, to: curr).day == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        let completedPoses = entries.map { $0.poseId.uuidString }
        return ExerciseMetrics(
            accuracy: accuracy,
            consistency: consistency,
            duration: duration,
            difficulty: difficulty,
            streak: maxStreak,
            completedPoses: completedPoses
        )
    }

    func updateStreaks(_ metrics: ExerciseMetrics) {
        // Placeholder
    }

    func checkAchievements(_ metrics: ExerciseMetrics) {
        for achievement in achievements where !achievement.isUnlocked {
            if achievement.requirements.isMet(by: metrics) {
                unlockAchievement(achievement)
                awardXP(achievement.xpReward)
            }
        }
    }

    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.email == rhs.email &&
        lhs.level == rhs.level &&
        lhs.xp == rhs.xp &&
        lhs.streakCount == rhs.streakCount &&
        lhs.profileImageData == rhs.profileImageData &&
        lhs.lastActiveDate == rhs.lastActiveDate &&
        lhs.achievements == rhs.achievements &&
        lhs.unlockedRoutines == rhs.unlockedRoutines &&
        lhs.unlockedAchievements == rhs.unlockedAchievements &&
        lhs.bestStreak == rhs.bestStreak &&
        lhs.goals == rhs.goals
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(email)
        hasher.combine(level)
        hasher.combine(xp)
        hasher.combine(streakCount)
        hasher.combine(profileImageData)
        hasher.combine(lastActiveDate)
        hasher.combine(achievements)
        hasher.combine(unlockedRoutines)
        hasher.combine(unlockedAchievements)
        hasher.combine(bestStreak)
        hasher.combine(goals)
    }

    fileprivate func unlockAchievement(_ achievement: Achievement) {
        var updated = achievements
        if let idx = updated.firstIndex(where: { $0.id == achievement.id }) {
            updated[idx].isUnlocked = true
            achievements = updated
            var unlocked = unlockedAchievements
            if !unlocked.contains(achievement.id) {
                unlocked.append(achievement.id)
                unlockedAchievements = unlocked
            }
        }
    }
    fileprivate func awardXP(_ amount: Int) {
        self.xp += amount
    }

    /// Calculate weighted accuracy for a set of pose log entries using joint weights
    func weightedAccuracy(from entries: [PoseLogEntry], jointWeights: [JointWeight]) -> Double {
        guard !entries.isEmpty, !jointWeights.isEmpty else { return 0.0 }
        // For each entry, compute weighted accuracy
        let weightedAccuracies: [Double] = entries.map { entry in
            let totalWeight = jointWeights.reduce(0.0) { $0 + $1.weight }
            guard totalWeight > 0 else { return 0.0 }
            let weightedSum = jointWeights.reduce(0.0) { sum, joint in
                let accuracy = entry.jointAccuracies[joint.name] ?? 0.0
                return sum + accuracy * joint.weight
            }
            return weightedSum / totalWeight
        }
        // Average across all entries
        return weightedAccuracies.reduce(0, +) / Double(weightedAccuracies.count)
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

struct JointWeight {
    let name: String
    let weight: Double
    let criticalThreshold: Double
}

struct ExerciseMetrics {
    let accuracy: Double
    let consistency: Double
    let duration: TimeInterval
    let difficulty: Int
    let streak: Int
    let completedPoses: [String]
    
    init(accuracy: Double, consistency: Double, duration: TimeInterval, difficulty: Int, streak: Int, completedPoses: [String] = []) {
        self.accuracy = accuracy
        self.consistency = consistency
        self.duration = duration
        self.difficulty = difficulty
        self.streak = streak
        self.completedPoses = completedPoses
    }
}



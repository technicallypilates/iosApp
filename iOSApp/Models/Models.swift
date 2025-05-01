import Foundation

enum Difficulty: String, Codable, Equatable, CaseIterable {
    case beginner
    case intermediate
    case advanced
}

enum Category: String, Codable, Equatable, CaseIterable {
    case mat
    case reformer
    case chair
    case cadillac
    case barrel
    case props
    case mixed
}

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
    let repsCompleted: Int
    let accuracy: Double
    let timestamp: Date
    let xpEarned: Int

    init(poseId: UUID, routineId: UUID, repsCompleted: Int, accuracy: Double, xpEarned: Int) {
        self.id = UUID()
        self.poseId = poseId
        self.routineId = routineId
        self.repsCompleted = repsCompleted
        self.accuracy = accuracy
        self.timestamp = Date()
        self.xpEarned = xpEarned
    }
}

struct Exercise: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var pose: Pose
    var duration: TimeInterval
    var repetitions: Int
    var instructions: [String]
    var category: Category

    init(id: UUID = UUID(), name: String, description: String, pose: Pose, duration: TimeInterval, repetitions: Int, instructions: [String], category: Category) {
        self.id = id
        self.name = name
        self.description = description
        self.pose = pose
        self.duration = duration
        self.repetitions = repetitions
        self.instructions = instructions
        self.category = category
    }
}

struct Routine: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var exercises: [Exercise]
    var duration: TimeInterval
    var difficulty: Difficulty
    var category: Category
    var isFavorite: Bool
    var lastCompleted: Date?
    var completionCount: Int

    init(id: UUID = UUID(), name: String, description: String, exercises: [Exercise], duration: TimeInterval, difficulty: Difficulty, category: Category, isFavorite: Bool = false, lastCompleted: Date? = nil, completionCount: Int = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.exercises = exercises
        self.duration = duration
        self.difficulty = difficulty
        self.category = category
        self.isFavorite = isFavorite
        self.lastCompleted = lastCompleted
        self.completionCount = completionCount
    }
}

struct Achievement: Identifiable, Codable, Equatable {
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

struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var targetXP: Int
    var currentXP: Int
    var isCompleted: Bool
    var deadline: Date?

    init(id: UUID = UUID(), title: String, description: String, targetXP: Int, currentXP: Int = 0, isCompleted: Bool = false, deadline: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.targetXP = targetXP
        self.currentXP = currentXP
        self.isCompleted = isCompleted
        self.deadline = deadline
    }
}

struct UserProfile: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let email: String
    var level: Int
    var xp: Int
    var streakCount: Int
    var goals: [Goal]
    var achievements: [Achievement]
    var unlockedAchievements: [Achievement]
    var lastWorkoutDate: Date?

    init(id: UUID = UUID(), name: String, email: String, level: Int = 1, xp: Int = 0, streakCount: Int = 0, goals: [Goal] = [], achievements: [Achievement] = [], unlockedAchievements: [Achievement] = [], lastWorkoutDate: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.level = level
        self.xp = xp
        self.streakCount = streakCount
        self.goals = goals
        self.achievements = achievements
        self.unlockedAchievements = unlockedAchievements
        self.lastWorkoutDate = lastWorkoutDate
    }

    mutating func addXP(_ amount: Int) {
        self.xp += amount
        self.streakCount += 1
        self.lastWorkoutDate = Date()

        let newLevel = (xp / 1000) + 1
        if newLevel > level {
            level = newLevel
        }
    }
}

struct XPSystem {
    static func calculateXP(accuracy: Double, isFirstTimeHighAccuracy: Bool = false, consecutiveCorrectPoses: Int = 0) -> Int {
        var xp: Int

        switch accuracy {
        case 0.9...1.0:
            xp = 100
        case 0.8..<0.9:
            xp = 80
        case 0.7..<0.8:
            xp = 60
        case 0.6..<0.7:
            xp = 40
        default:
            xp = 0
        }

        if accuracy >= 0.95 {
            xp *= 2
        }

        if consecutiveCorrectPoses > 0 {
            xp += Int(Double(xp) * (0.1 * Double(consecutiveCorrectPoses)))
        }

        if isFirstTimeHighAccuracy && accuracy >= 0.9 {
            xp += 50
        }

        return xp
    }
}

// ✅ Example Routine
extension Routine {
    static let exampleRoutine = Routine(
        id: UUID(),
        name: "Example Routine",
        description: "This is an example Pilates routine.",
        exercises: [],
        duration: 20 * 60,
        difficulty: .beginner,
        category: .mixed,
        isFavorite: false,
        lastCompleted: nil,
        completionCount: 0
    )
}


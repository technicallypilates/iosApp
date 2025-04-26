// Models.swift

import Foundation

struct Pose: Codable, Equatable {
    var name: String
}

struct PoseLogEntry: Codable, Identifiable {
    var id = UUID()
    var routine: String
    var pose: String
    var timestamp: Date
    var repsCompleted: Int
}

struct Routine: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var poses: [Pose]

    var displayName: String {
        return name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Routine, rhs: Routine) -> Bool {
        return lhs.id == rhs.id
    }

    static let standing = Routine(name: "Standing", poses: [Pose(name: "Pose 1"), Pose(name: "Pose 2")])
    static let core = Routine(name: "Core", poses: [Pose(name: "Pose 1"), Pose(name: "Pose 2")])
    static let armsBack = Routine(name: "Arms & Back", poses: [Pose(name: "Pose 1"), Pose(name: "Pose 2")])
    static let stretch = Routine(name: "Stretch", poses: [Pose(name: "Pose 1"), Pose(name: "Pose 2")])
    static let legsGlutes = Routine(name: "Legs & Glutes", poses: [Pose(name: "Pose 1"), Pose(name: "Pose 2")])

    static let all: [Routine] = [.standing, .core, .armsBack, .stretch, .legsGlutes]
}

struct UserProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var xp: Int = 0
    var level: Int = 1
    var streakCount: Int = 0
    var lastActiveDate: Date? = nil
    var unlockedAchievements: [String] = []
    var unlockedRoutines: [Routine] = [Routine.standing]

    mutating func updateProgress(with newEntry: PoseLogEntry) {
        xp += 10
        level = (xp / 100) + 1

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastActiveDate {
            let last = calendar.startOfDay(for: lastDate)
            if calendar.isDate(last, inSameDayAs: today) {
                // same day
            } else if let diff = calendar.dateComponents([.day], from: last, to: today).day, diff == 1 {
                streakCount += 1
            } else {
                streakCount = 1
            }
        } else {
            streakCount = 1
        }

        lastActiveDate = today

        if streakCount == 3, !unlockedAchievements.contains("3-Day Streak") {
            unlockedAchievements.append("3-Day Streak")
        }
        if xp >= 100, !unlockedAchievements.contains("Level Up") {
            unlockedAchievements.append("Level Up")
        }

        if level >= 2, !unlockedRoutines.contains(Routine.core) {
            unlockedRoutines.append(.core)
        }
        if level >= 3, !unlockedRoutines.contains(.stretch) {
            unlockedRoutines.append(.stretch)
        }
        if level >= 4, !unlockedRoutines.contains(.armsBack) {
            unlockedRoutines.append(.armsBack)
        }
        if level >= 5, !unlockedRoutines.contains(.legsGlutes) {
            unlockedRoutines.append(.legsGlutes)
        }
    }
}



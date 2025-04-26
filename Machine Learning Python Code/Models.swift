// Models.swift

import Foundation

struct Pose: Codable {
    var name: String
}

struct PoseLogEntry: Codable, Identifiable {
    var id = UUID()
    var routine: String
    var pose: String
    var timestamp: Date
    var repsCompleted: Int
}

enum Routine: String, Codable, CaseIterable, Identifiable {
    case standing, core, armsBack, stretch, legsGlutes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standing: return "Standing"
        case .core: return "Core"
        case .armsBack: return "Arms & Back"
        case .stretch: return "Stretch"
        case .legsGlutes: return "Legs & Glutes"
        }
    }

    var poses: [Pose] {
        [Pose(name: "Pose 1"), Pose(name: "Pose 2")]
    }
}

struct UserProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var xp: Int = 0
    var level: Int = 1
    var streakCount: Int = 0
    var lastActiveDate: Date? = nil
    var unlockedAchievements: [String] = []
    var unlockedRoutines: [Routine] = [.standing]

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

        if level >= 2, !unlockedRoutines.contains(.core) {
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


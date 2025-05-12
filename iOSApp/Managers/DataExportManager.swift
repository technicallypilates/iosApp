import Foundation
import FirebaseFirestore

class DataExportManager {
    static let shared = DataExportManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Data Export
    
    struct ExportData: Codable {
        let userProfile: UserProfile
        let routines: [Routine]
        let poseLogs: [PoseLogEntry]
        let achievements: [Achievement]
        let socialProfile: SocialManager.SocialProfile?
        let exportDate: Date
        let version: String
    }
    
    func exportUserData() async throws -> ExportData {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "DataExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        async let userProfile = db.collection("users").document(userId).getDocument()
        async let routines = db.collection("routines").whereField("userId", isEqualTo: userId).getDocuments()
        async let poseLogs = db.collection("users").document(userId).collection("poseLogs").getDocuments()
        async let achievements = db.collection("users").document(userId).collection("achievements").getDocuments()
        async let socialProfile = db.collection("social_profiles").document(userId).getDocument()
        
        let (profileDoc, routinesSnapshot, logsSnapshot, achievementsSnapshot, socialProfileDoc) = try await (userProfile, routines, poseLogs, achievements, socialProfile)
        
        guard let profile = try? profileDoc.data(as: UserProfile.self) else {
            throw NSError(domain: "DataExport", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode user profile"])
        }
        
        let routinesList = try routinesSnapshot.documents.compactMap { try $0.data(as: Routine.self) }
        let poseLogsList = try logsSnapshot.documents.compactMap { try $0.data(as: PoseLogEntry.self) }
        let achievementsList = try achievementsSnapshot.documents.compactMap { try $0.data(as: Achievement.self) }
        let socialProfileObj = try? socialProfileDoc.data(as: SocialManager.SocialProfile.self)
        
        return ExportData(
            userProfile: profile,
            routines: routinesList,
            poseLogs: poseLogsList,
            achievements: achievementsList,
            socialProfile: socialProfileObj,
            exportDate: Date(),
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }
    
    // MARK: - Export Formats
    
    func exportToJSON() async throws -> Data {
        let exportData = try await exportUserData()
        return try JSONEncoder().encode(exportData)
    }
    
    func exportToCSV() async throws -> String {
        let exportData = try await exportUserData()
        
        var csvString = "Type,ID,Name,Date,Details\n"
        
        // Export routines
        for routine in exportData.routines {
            csvString += "Routine,\(routine.id),\(routine.name),,\(routine.description)\n"
        }
        
        // Export pose logs
        for log in exportData.poseLogs {
            csvString += "PoseLog,\(log.id),\(log.poseId),\(log.timestamp),Accuracy: \(log.accuracyScore)\n"
        }
        
        // Export achievements
        for achievement in exportData.achievements {
            csvString += "Achievement,\(achievement.id),\(achievement.name),,\(achievement.description)\n"
        }
        
        return csvString
    }
    
    // MARK: - Data Backup
    
    func createBackup() async throws {
        let exportData = try await exportToJSON()
        let backupName = "backup_\(Date().timeIntervalSince1970).json"
        try DataManager.shared.save(exportData, to: backupName)
    }
    
    func restoreFromBackup(_ backupName: String) async throws {
        let data = try DataManager.shared.load(Data.self, from: backupName)
        let exportData = try JSONDecoder().decode(ExportData.self, from: data)
        
        // Restore user profile
        guard let profileDict = exportData.userProfile.dictionary else {
            throw NSError(domain: "DataExport", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to convert user profile to dictionary"])
        }
        try await db.collection("users").document(profileDict["id"] as! String).setData(profileDict)
        
        // Restore routines
        for routine in exportData.routines {
            if let data = routine.dictionary {
                try await db.collection("routines").document(routine.id.uuidString).setData(data)
            }
        }
        
        // Restore pose logs
        for log in exportData.poseLogs {
            let data = log.dictionary
            try await db.collection("users").document(exportData.userProfile.id)
                .collection("poseLogs")
                .document(log.id.uuidString)
                .setData(data)
        }
        
        // Restore achievements
        for achievement in exportData.achievements {
            let data = achievement.dictionary
            try await db.collection("users").document(exportData.userProfile.id)
                .collection("achievements")
                .document(achievement.id.uuidString)
                .setData(data)
        }
        
        // Restore social profile
        if let socialProfile = exportData.socialProfile {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(socialProfile)
            let data = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] ?? [:]
            try await db.collection("social_profiles").document(exportData.userProfile.id).setData(data)
        }
    }
    
    // MARK: - Data Deletion
    
    func deleteUserData() async throws {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        // Delete user profile
        try await db.collection("users").document(userId).delete()
        
        // Delete routines
        let routines = try await db.collection("routines")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for document in routines.documents {
            try await document.reference.delete()
        }
        
        // Delete pose logs
        let logs = try await db.collection("users")
            .document(userId)
            .collection("poseLogs")
            .getDocuments()
        
        for document in logs.documents {
            try await document.reference.delete()
        }
        
        // Delete achievements
        let achievements = try await db.collection("users")
            .document(userId)
            .collection("achievements")
            .getDocuments()
        
        for document in achievements.documents {
            try await document.reference.delete()
        }
        
        // Delete social profile
        try await db.collection("social_profiles").document(userId).delete()
    }
} 
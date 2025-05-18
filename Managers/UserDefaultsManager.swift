import Foundation
import UIKit
import os.log

class UserDefaultsManager: NSObject {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "com.technicallypilates.userdefaults")
    private let logger = OSLog(subsystem: "com.technicallypilates", category: "UserDefaults")
    private var syncQueue: [SyncOperation] = []
    private var lastSyncTime: Date?
    
    override private init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - Advanced User Preferences
    
    func setUserPreference<T>(_ value: T, forKey key: String, sync: Bool = true) {
        queue.async {
            self.defaults.set(value, forKey: key)
            
            if sync {
                self.syncQueue.append(SyncOperation(key: key, value: value))
            }
            
            os_log("Set preference for key: %{public}@", log: self.logger, type: .debug, key)
        }
    }
    
    func getUserPreference<T>(forKey key: String, defaultValue: T) -> T {
        return defaults.object(forKey: key) as? T ?? defaultValue
    }
    
    func removeUserPreference(forKey key: String, sync: Bool = true) {
        queue.async {
            self.defaults.removeObject(forKey: key)
            
            if sync {
                self.syncQueue.append(SyncOperation(key: key, value: nil))
            }
            
            os_log("Removed preference for key: %{public}@", log: self.logger, type: .debug, key)
        }
    }
    
    // MARK: - Advanced User Settings
    
    func setUserSettings(_ settings: UserSettings, sync: Bool = true) {
        queue.async {
            if let encoded = try? JSONEncoder().encode(settings) {
                self.defaults.set(encoded, forKey: "user_settings")
                
                if sync {
                    self.syncQueue.append(SyncOperation(key: "user_settings", value: encoded))
                }
                
                os_log("Updated user settings", log: self.logger, type: .debug)
            }
        }
    }
    
    func getUserSettings() -> UserSettings? {
        guard let data = defaults.data(forKey: "user_settings") else {
            return nil
        }
        return try? JSONDecoder().decode(UserSettings.self, from: data)
    }
    
    // MARK: - Advanced App State
    
    func saveAppState(_ state: AppState, sync: Bool = true) {
        queue.async {
            if let encoded = try? JSONEncoder().encode(state) {
                self.defaults.set(encoded, forKey: "app_state")
                
                if sync {
                    self.syncQueue.append(SyncOperation(key: "app_state", value: encoded))
                }
                
                os_log("Saved app state", log: self.logger, type: .debug)
            }
        }
    }
    
    func getAppState() -> AppState? {
        guard let data = defaults.data(forKey: "app_state") else {
            return nil
        }
        return try? JSONDecoder().decode(AppState.self, from: data)
    }
    
    // MARK: - Advanced Workout History
    
    func saveWorkoutHistory(_ history: [WorkoutSession], sync: Bool = true) {
        queue.async {
            if let encoded = try? JSONEncoder().encode(history) {
                self.defaults.set(encoded, forKey: "workout_history")
                
                if sync {
                    self.syncQueue.append(SyncOperation(key: "workout_history", value: encoded))
                }
                
                os_log("Saved workout history", log: self.logger, type: .debug)
            }
        }
    }
    
    func getWorkoutHistory() -> [WorkoutSession]? {
        guard let data = defaults.data(forKey: "workout_history") else {
            return nil
        }
        return try? JSONDecoder().decode([WorkoutSession].self, from: data)
    }
    
    // MARK: - Advanced Achievement Progress
    
    func saveAchievementProgress(_ progress: [AchievementProgress], sync: Bool = true) {
        queue.async {
            if let encoded = try? JSONEncoder().encode(progress) {
                self.defaults.set(encoded, forKey: "achievement_progress")
                
                if sync {
                    self.syncQueue.append(SyncOperation(key: "achievement_progress", value: encoded))
                }
                
                os_log("Saved achievement progress", log: self.logger, type: .debug)
            }
        }
    }
    
    func getAchievementProgress() -> [AchievementProgress]? {
        guard let data = defaults.data(forKey: "achievement_progress") else {
            return nil
        }
        return try? JSONDecoder().decode([AchievementProgress].self, from: data)
    }
    
    // MARK: - Advanced Data Management
    
    func clearAllData() {
        queue.async {
            let dictionary = self.defaults.dictionaryRepresentation()
            dictionary.keys.forEach { key in
                self.defaults.removeObject(forKey: key)
            }
            
            self.syncQueue.removeAll()
            
            os_log("Cleared all data", log: self.logger, type: .debug)
        }
    }
    
    func clearSpecificData(forKeys keys: [String]) {
        queue.async {
            keys.forEach { key in
                self.defaults.removeObject(forKey: key)
                self.syncQueue.append(SyncOperation(key: key, value: nil))
            }
            
            os_log("Cleared specific data for keys: %{public}@", log: self.logger, type: .debug, keys.joined(separator: ", "))
        }
    }
    
    // MARK: - Advanced Data Migration
    
    func migrateData(from oldKey: String, to newKey: String) async {
        await withCheckedContinuation { continuation in
            queue.async {
                if let value = self.defaults.object(forKey: oldKey) as? NSObject {
                    self.defaults.set(value, forKey: newKey)
                    self.defaults.removeObject(forKey: oldKey)
                    
                    self.syncQueue.append(SyncOperation(key: newKey, value: value))
                    
                    os_log("Migrated data from %{public}@ to %{public}@", log: self.logger, type: .debug, oldKey, newKey)
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Advanced Data Validation
    
    func validateData(forKey key: String) -> Bool {
        return defaults.object(forKey: key) != nil
    }
    
    func validateDataStructure<T: Codable>(forKey key: String, type: T.Type) -> Bool {
        guard let data = defaults.data(forKey: key) else {
            return false
        }
        return (try? JSONDecoder().decode(type, from: data)) != nil
    }
    
    // MARK: - Advanced Data Backup
    
    func backupData() -> [String: Any] {
        var backup: [String: Any] = [:]
        let dictionary = defaults.dictionaryRepresentation()
        
        for (key, value) in dictionary {
            backup[key] = value
        }
        
        os_log("Created data backup", log: logger, type: .debug)
        return backup
    }
    
    func restoreFromBackup(_ backup: [String: Any]) {
        queue.async {
            for (key, value) in backup {
                self.defaults.set(value, forKey: key)
            }
            
            os_log("Restored data from backup", log: self.logger, type: .debug)
        }
    }
    
    // MARK: - Advanced Data Synchronization
    
    func syncData() async {
        await withCheckedContinuation { continuation in
            queue.async {
                guard !self.syncQueue.isEmpty else {
                    continuation.resume()
                    return
                }
                
                let operations = self.syncQueue
                self.syncQueue.removeAll()
                
                Task {
                    for operation in operations {
                        do {
                            // Implement your sync logic here
                            // For example, sync with iCloud or your backend
                            try await self.syncOperation(operation)
                            os_log("Synced data for key: %{public}@", log: self.logger, type: .debug, operation.key)
                        } catch {
                            os_log("Failed to sync data for key: %{public}@ - %{public}@",
                                   log: self.logger,
                                   type: .error,
                                   operation.key,
                                   error.localizedDescription)
                        }
                    }
                    
                    self.lastSyncTime = Date()
                    continuation.resume()
                }
            }
        }
    }
    
    private func syncOperation(_ operation: SyncOperation) async throws {
        // Implement your sync logic here
        // This is a placeholder for actual sync implementation
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
    }
    
    // MARK: - Advanced Data Observation
    
    func observeChanges(forKey key: String) async -> AsyncStream<Any?> {
        AsyncStream { continuation in
            defaults.addObserver(self, forKeyPath: key, options: [.new], context: nil)
            continuation.onTermination = { [weak self] _ in
                if let strongSelf = self {
                    strongSelf.defaults.removeObserver(strongSelf, forKeyPath: key)
                }
            }
        }
    }
    
    // MARK: - App State Handling
    
    @objc private func handleAppStateChange() {
        Task { await self.syncData() }
    }
    
    // MARK: - Advanced Batch Operations
    
    func batchUpdate(_ updates: [(key: String, value: Any)], sync: Bool = true) async {
        await withCheckedContinuation { continuation in
            queue.async {
                for (key, value) in updates {
                    self.defaults.set(value, forKey: key)
                    
                    if sync {
                        self.syncQueue.append(SyncOperation(key: key, value: value))
                    }
                }
                
                os_log("Performed batch update for %d items", log: self.logger, type: .debug, updates.count)
                continuation.resume()
            }
        }
    }
    
    func batchDelete(_ keys: [String], sync: Bool = true) async {
        await withCheckedContinuation { continuation in
            queue.async {
                for key in keys {
                    self.defaults.removeObject(forKey: key)
                    
                    if sync {
                        self.syncQueue.append(SyncOperation(key: key, value: nil))
                    }
                }
                
                os_log("Performed batch delete for %d items", log: self.logger, type: .debug, keys.count)
                continuation.resume()
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // ... existing code ...
    }
    
    func saveValue(_ value: Any, forKey key: String) {
        // ... existing code ...
    }
}

// MARK: - Supporting Types

struct SyncOperation {
    let key: String
    let value: Any?
    let timestamp = Date()
}

struct UserSettings: Codable {
    var notificationsEnabled: Bool
    var soundEnabled: Bool
    var darkModeEnabled: Bool
    var autoPlayEnabled: Bool
    var language: String
    var measurementSystem: String
}

struct WorkoutSession: Codable {
    var id: UUID
    var date: Date
    var duration: TimeInterval
    var exercises: [Exercise]
    var caloriesBurned: Int
    var averageAccuracy: Double
}

struct AchievementProgress: Codable {
    var id: UUID
    var name: String
    var progress: Double
    var isCompleted: Bool
    var dateCompleted: Date?
}

struct Exercise: Codable {
    var id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var accuracy: Double
} 
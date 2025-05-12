import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import os.log
// Uncomment if using Crashlytics
// import FirebaseCrashlytics

// MARK: - Supporting Types

enum FirebaseError: Error {
    case networkError(String)
    case quotaExceeded(String)
    case transactionFailed(String)
    case invalidData(String)
    case cacheError(String)
    case documentNotFound(String)
    case unknown(String)
}

enum PendingOperation {
    case updateUserXP(userId: String, amount: Int)
    case updatePredictionScore(userId: String, poseId: UUID, score: Double)
    case batchUpdatePoseLogs(logs: [PoseLogEntry], userId: String)
}

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let db: Firestore = Firestore.firestore()
    private let cacheManager: CacheManager = CacheManager.shared
    private let performanceManager: PerformanceManager = PerformanceManager.shared
    private let networkManager: NetworkManager = NetworkManager.shared
    private let batchSize: Int = 500
    private let maxRetries: Int = 3
    private let retryDelay: TimeInterval = 1.0
    private var pendingOperations: [PendingOperation] = []
    private let pendingOpsQueue = DispatchQueue(label: "com.technicallypilates.pendingOps")
    private let logger = OSLog(subsystem: "com.technicallypilates", category: "FirebaseManager")
    
    struct RetryPolicy {
        let maxRetries: Int
        let initialDelay: TimeInterval
        let backoffMultiplier: Double
        let jitter: TimeInterval
        static let `default` = RetryPolicy(maxRetries: 3, initialDelay: 1.0, backoffMultiplier: 2.0, jitter: 0.5)
        static let aggressive = RetryPolicy(maxRetries: 5, initialDelay: 0.5, backoffMultiplier: 1.5, jitter: 1.0)
    }
    
    private init() {
        setupFirestoreSettings()
    }
    
    // MARK: - Firestore Settings
    
    private func setupFirestoreSettings() {
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        db.settings = settings
    }
    
    // MARK: - Retry Logic
    
    private func retryOperation<T>(
        policy: RetryPolicy = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var currentDelay = policy.initialDelay
        for attempt in 0..<policy.maxRetries {
            do {
                return try await operation()
            } catch let error as FirebaseError {
                lastError = error
                if isRetryable(error: error) && attempt < policy.maxRetries - 1 {
                    let jitter = Double.random(in: 0...policy.jitter)
                    os_log("Retrying operation (attempt %d/%d) after %.2fs (jitter %.2fs): %{public}@", log: logger, type: .info, attempt+1, policy.maxRetries, currentDelay, jitter, String(describing: error))
                    try await Task.sleep(nanoseconds: UInt64((currentDelay + jitter) * 1_000_000_000))
                    currentDelay *= policy.backoffMultiplier
                    continue
                } else {
                    throw error
                }
            } catch {
                lastError = error
                if attempt < policy.maxRetries - 1 {
                    let jitter = Double.random(in: 0...policy.jitter)
                    os_log("Retrying operation (attempt %d/%d) after %.2fs (jitter %.2fs): %{public}@", log: logger, type: .info, attempt+1, policy.maxRetries, currentDelay, jitter, String(describing: error))
                    try await Task.sleep(nanoseconds: UInt64((currentDelay + jitter) * 1_000_000_000))
                    currentDelay *= policy.backoffMultiplier
                    continue
                }
            }
        }
        throw lastError ?? FirebaseError.unknown("Operation failed after \(policy.maxRetries) attempts")
    }
    
    private func isRetryable(error: FirebaseError) -> Bool {
        switch error {
        case .networkError, .quotaExceeded, .transactionFailed:
            return true
        default:
            return false
        }
    }
    
    // MARK: - XP and Prediction Score Management
    
    func updateUserXP(_ userId: String, amount: Int) async throws {
        let userRef: DocumentReference = db.collection("users").document(userId)
        
        do {
            try await retryOperation(policy: .default) { [self] in
                try await self.db.runTransaction { [self] transaction, errorPointer in
                    let snapshot: DocumentSnapshot
                    do {
                        snapshot = try transaction.getDocument(userRef)
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        os_log("Transaction fetch error for userXP: %{public}@", log: self.logger, type: .error, fetchError.localizedDescription)
                        return nil
                    }
                    guard let oldXP = snapshot.data()? ["xp"] as? Int else {
                        let error = NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "XP field not found in user document"])
                        errorPointer?.pointee = error
                        os_log("XP field not found in user document: %{public}@", log: self.logger, type: .error, userId)
                        return nil
                    }
                    let newXP = oldXP + amount
                    let newLevel = Int(sqrt(Double(newXP) / 100)) + 1
                    transaction.updateData([
                        "xp": newXP,
                        "level": newLevel,
                        "lastUpdated": FieldValue.serverTimestamp()
                    ], forDocument: userRef)
                    os_log("Updated user XP for %{public}@ to %{public}d", log: self.logger, type: .info, userId, newXP)
                    return nil
                }
            }
        } catch {
            os_log("Error in updateUserXP: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }
    
    func updatePredictionScore(_ userId: String, poseId: UUID, score: Double) async throws {
        let batch: WriteBatch = db.batch()
        let userRef: DocumentReference = db.collection("users").document(userId)
        let poseLogRef: DocumentReference = userRef.collection("poseLogs").document()
        
        do {
            // Add pose log entry
            let poseLog = PoseLogEntry(
                poseId: poseId,
                routineId: UUID(), // Set appropriate routine ID
                repsCompleted: 1,
                accuracyScore: Int(score * 100),
                timestamp: Date()
            )
            let data = poseLog.dictionary
            batch.setData(data, forDocument: poseLogRef)
            try await batch.commit()
            os_log("Committed pose log for user %{public}@", log: logger, type: .info, userId)
            // Update cache
            do {
                if let cachedProfile = try cacheManager.getCachedModel(forKey: "user_\(userId)") as UserProfile? {
                    try cacheManager.cacheModel(cachedProfile, forKey: "user_\(userId)", expirationInterval: 3600)
                    os_log("Updated cache after pose log for %{public}@", log: logger, type: .info, userId)
                }
            } catch {
                os_log("Cache update error after pose log for %{public}@, %{public}@", log: logger, type: .error, userId, error.localizedDescription)
                // Crashlytics.crashlytics().record(error: error)
                throw FirebaseError.cacheError("Failed to update cached profile: \(error.localizedDescription)")
            }
        } catch let error as FirebaseError {
            if case .networkError = error {
                enqueuePendingOperation(.updatePredictionScore(userId: userId, poseId: poseId, score: score))
                os_log("Enqueued pending updatePredictionScore for %{public}@ due to network error", log: logger, type: .info, userId)
            }
            os_log("FirebaseError in updatePredictionScore: %{public}@", log: logger, type: .error, error.localizedDescription)
            // Crashlytics.crashlytics().record(error: error)
            throw error
        } catch {
            os_log("Unknown error in updatePredictionScore: %{public}@", log: logger, type: .error, error.localizedDescription)
            // Crashlytics.crashlytics().record(error: error)
            throw error
        }
    }
    
    // MARK: - Real-time Updates
    
    func observeUserProgress(_ userId: String, completion: @escaping (Result<UserProfile, FirebaseError>) -> Void) -> ListenerRegistration {
        return db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(.unknown("Failed to observe user progress: \(error.localizedDescription)")))
                    return
                }
                
                guard let self = self,
                      let data = snapshot?.data() else {
                    completion(.failure(.documentNotFound("User document not found")))
                    return
                }
                
                do {
                    guard let profile = try UserProfile(dictionary: data) else {
                        completion(.failure(.invalidData("Failed to decode user profile")))
                        return
                    }
                    
                    do {
                        try self.cacheManager.cacheModel(profile, forKey: "user_\(userId)")
                        completion(.success(profile))
                    } catch {
                        completion(.failure(.cacheError("Failed to cache user profile: \(error.localizedDescription)")))
                    }
                } catch {
                    completion(.failure(.invalidData("Failed to decode user profile: \(error.localizedDescription)")))
                }
            }
    }
    
    // MARK: - Batch Operations
    
    func batchUpdatePoseLogs(_ logs: [PoseLogEntry], userId: String) async throws {
        let userRef: DocumentReference = db.collection("users").document(userId)
        // Split logs into chunks to prevent timeouts
        let chunks = stride(from: 0, to: logs.count, by: batchSize).map {
            Array(logs[$0..<min($0 + batchSize, logs.count)])
        }
        for chunk in chunks {
            do {
                try await retryOperation(policy: .aggressive, operation: { [self] () async throws -> Void in
                    let batch: WriteBatch = self.db.batch()
                    for log in chunk {
                        let data = log.dictionary
                        let logRef: DocumentReference = userRef.collection("poseLogs").document(log.id.uuidString)
                        batch.setData(data, forDocument: logRef)
                    }
                    try await batch.commit()
                    os_log("Committed batch pose logs for user %{public}@", log: self.logger, type: .info, userId)
                    // Update cache for each chunk
                    do {
                        if let cachedProfile = try self.cacheManager.getCachedModel(forKey: "user_\(userId)") as UserProfile? {
                            try self.cacheManager.cacheModel(cachedProfile, forKey: "user_\(userId)", expirationInterval: 3600)
                            os_log("Updated cache after batch pose logs for %{public}@", log: self.logger, type: .info, userId)
                        }
                    } catch {
                        os_log("Cache update error after batch pose logs for %{public}@, %{public}@", log: self.logger, type: .error, userId, error.localizedDescription)
                        // Crashlytics.crashlytics().record(error: error)
                        throw FirebaseError.cacheError("Failed to update cached profile: \(error.localizedDescription)")
                    }
                })
            } catch let error as FirebaseError {
                if case .networkError = error {
                    enqueuePendingOperation(.batchUpdatePoseLogs(logs: chunk, userId: userId))
                    os_log("Enqueued pending batchUpdatePoseLogs for %{public}@ due to network error", log: logger, type: .info, userId)
                }
                os_log("FirebaseError in batchUpdatePoseLogs: %{public}@", log: logger, type: .error, error.localizedDescription)
                // Crashlytics.crashlytics().record(error: error)
                throw error
            } catch {
                os_log("Unknown error in batchUpdatePoseLogs: %{public}@", log: logger, type: .error, error.localizedDescription)
                // Crashlytics.crashlytics().record(error: error)
                throw error
            }
        }
    }
    
    // MARK: - Offline Support
    
    func enableOfflineSupport() {
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        db.settings = settings
    }
    
    // MARK: - Cache Management
    
    func clearCache() throws {
        do {
            cacheManager.clearMemoryCache()
            try cacheManager.clearDiskCache()
            try cacheManager.clearExpiredCache() // New method to clear expired cache entries
        } catch {
            throw FirebaseError.cacheError("Failed to clear cache: \(error.localizedDescription)")
        }
    }
    
    func getCacheStats() throws -> CacheStats {
        do {
            var stats = try cacheManager.getCacheStats()
            stats.expiredEntries = try cacheManager.getExpiredCacheEntriesCount() // New method
            return stats
        } catch {
            throw FirebaseError.cacheError("Failed to get cache stats: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Network Status Monitoring
    
    func startNetworkMonitoring() {
        networkManager.startMonitoring { [weak self] isConnected in
            if isConnected {
                // Attempt to sync any pending operations
                Task { [weak self] in
                    guard let self = self else { return }
                    try? await self.syncPendingOperations()
                }
            }
        }
    }
    
    func syncPendingOperations() async throws {
        let ops = dequeueAllPendingOperations()
        for op in ops {
            do {
                switch op {
                case .updateUserXP(let userId, let amount):
                    try await updateUserXP(userId, amount: amount)
                case .updatePredictionScore(let userId, let poseId, let score):
                    try await updatePredictionScore(userId, poseId: poseId, score: score)
                case .batchUpdatePoseLogs(let logs, let userId):
                    try await batchUpdatePoseLogs(logs, userId: userId)
                }
                os_log("Successfully synced pending operation: %{public}@", log: logger, type: .info, String(describing: op))
            } catch {
                os_log("Failed to sync pending operation: %{public}@, error: %{public}@", log: logger, type: .error, String(describing: op), error.localizedDescription)
                // Crashlytics.crashlytics().record(error: error)
                // If it fails again, re-enqueue for next attempt
                enqueuePendingOperation(op)
            }
        }
    }
    
    // MARK: - Pending Operations Queue
    
    private func enqueuePendingOperation(_ op: PendingOperation) {
        pendingOpsQueue.async {
            self.pendingOperations.append(op)
            os_log("Enqueued pending operation: %{public}@", log: self.logger, type: .info, String(describing: op))
            // Optionally: persist to disk for robustness
        }
    }
    
    private func dequeueAllPendingOperations() -> [PendingOperation] {
        var ops: [PendingOperation] = []
        pendingOpsQueue.sync {
            ops = self.pendingOperations
            self.pendingOperations.removeAll()
            os_log("Dequeued all pending operations. Count: %{public}d", log: self.logger, type: .info, ops.count)
        }
        return ops
    }
} 
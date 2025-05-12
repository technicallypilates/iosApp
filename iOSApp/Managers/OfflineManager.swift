import Foundation
import Network

class OfflineManager {
    static let shared = OfflineManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "OfflineManager")
    private var isOnline = true
    private var pendingOperations: [OfflineOperation] = []
    
    private init() {
        setupNetworkMonitoring()
        loadPendingOperations()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isOnline = path.status == .satisfied
            if path.status == .satisfied {
                self?.processPendingOperations()
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Offline Operations
    
    struct OfflineOperation: Codable {
        let id: UUID
        let type: OperationType
        let data: Data
        let timestamp: Date
        
        enum OperationType: String, Codable {
            case saveRoutine
            case syncPoseData
            case updateUserProfile
        }
    }
    
    func queueOperation(_ operation: OfflineOperation) {
        pendingOperations.append(operation)
        savePendingOperations()
    }
    
    private func processPendingOperations() {
        guard isOnline else { return }
        
        let operations = pendingOperations
        pendingOperations.removeAll()
        
        for operation in operations {
            processOperation(operation)
        }
    }
    
    private func processOperation(_ operation: OfflineOperation) {
        switch operation.type {
        case .saveRoutine:
            if let routine = try? JSONDecoder().decode(Routine.self, from: operation.data) {
                Task {
                    try? await saveRoutine(routine)
                }
            }
        case .syncPoseData:
            if let poseData = try? JSONDecoder().decode(PoseLogEntry.self, from: operation.data) {
                Task {
                    try? await syncPoseData(poseData)
                }
            }
        case .updateUserProfile:
            if let profile = try? JSONDecoder().decode(UserProfile.self, from: operation.data) {
                Task {
                    try? await updateUserProfile(profile)
                }
            }
        }
    }
    
    // MARK: - Data Persistence
    
    private func savePendingOperations() {
        do {
            let data = try JSONEncoder().encode(pendingOperations)
            try DataManager.shared.save(data, to: "pending_operations.json")
        } catch {
            CrashReportingManager.shared.reportError(error, context: "OfflineManager.savePendingOperations")
        }
    }
    
    private func loadPendingOperations() {
        do {
            let data = try DataManager.shared.load(Data.self, from: "pending_operations.json")
            pendingOperations = try JSONDecoder().decode([OfflineOperation].self, from: data)
        } catch {
            CrashReportingManager.shared.reportError(error, context: "OfflineManager.loadPendingOperations")
        }
    }
    
    // MARK: - Network Operations
    
    private func saveRoutine(_ routine: Routine) async throws {
        guard isOnline else {
            let operation = OfflineOperation(
                id: UUID(),
                type: .saveRoutine,
                data: try JSONEncoder().encode(routine),
                timestamp: Date()
            )
            queueOperation(operation)
            return
        }
        
        // TODO: Implement actual online save routine logic
    }
    
    private func syncPoseData(_ poseData: PoseLogEntry) async throws {
        guard isOnline else {
            let operation = OfflineOperation(
                id: UUID(),
                type: .syncPoseData,
                data: try JSONEncoder().encode(poseData),
                timestamp: Date()
            )
            queueOperation(operation)
            return
        }
        
        // TODO: Implement actual online sync logic
    }
    
    private func updateUserProfile(_ profile: UserProfile) async throws {
        guard isOnline else {
            let operation = OfflineOperation(
                id: UUID(),
                type: .updateUserProfile,
                data: try JSONEncoder().encode(profile),
                timestamp: Date()
            )
            queueOperation(operation)
            return
        }
        
        // TODO: Implement actual online update logic
    }
    
    // MARK: - Status
    
    var isDeviceOnline: Bool {
        return isOnline
    }
    
    var hasPendingOperations: Bool {
        return !pendingOperations.isEmpty
    }
    
    func clearPendingOperations() {
        pendingOperations.removeAll()
        savePendingOperations()
    }
}


import Foundation
import Combine

class ViewModel: ObservableObject {
    @Published var poses: [Pose] = []
    @Published var routines: [Routine] = []
    @Published var userProfile: UserProfile?
    @Published var poseLog: [PoseLogEntry] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadData()
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        do {
            if DataManager.shared.fileExists(fileName: "poses.json") {
                poses = try DataManager.shared.load([Pose].self, from: "poses.json")
            }
            
            if DataManager.shared.fileExists(fileName: "routines.json") {
                routines = try DataManager.shared.load([Routine].self, from: "routines.json")
            }
            
            if DataManager.shared.fileExists(fileName: "userProfile.json") {
                userProfile = try DataManager.shared.load(UserProfile.self, from: "userProfile.json")
            }
            
            if DataManager.shared.fileExists(fileName: "poseLog.json") {
                poseLog = try DataManager.shared.load([PoseLogEntry].self, from: "poseLog.json")
            }
        } catch {
            print("Error loading data: \(error)")
        }
    }
    
    // MARK: - Pose Management
    
    func addPose(_ pose: Pose) {
        poses.append(pose)
        savePoses()
    }
    
    func updatePose(_ pose: Pose) {
        if let index = poses.firstIndex(where: { $0.id == pose.id }) {
            poses[index] = pose
            savePoses()
        }
    }
    
    func deletePose(_ pose: Pose) {
        poses.removeAll { $0.id == pose.id }
        savePoses()
    }
    
    private func savePoses() {
        do {
            try DataManager.shared.save(poses, to: "poses.json")
        } catch {
            print("Error saving poses: \(error)")
        }
    }
    
    // MARK: - Routine Management
    
    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        saveRoutines()
    }
    
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
            saveRoutines()
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        saveRoutines()
    }
    
    private func saveRoutines() {
        do {
            try DataManager.shared.save(routines, to: "routines.json")
        } catch {
            print("Error saving routines: \(error)")
        }
    }
    
    // MARK: - User Profile Management
    
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
    }
    
    private func saveUserProfile() {
        guard let profile = userProfile else { return }
        do {
            try DataManager.shared.save(profile, to: "userProfile.json")
        } catch {
            print("Error saving user profile: \(error)")
        }
    }
    
    // MARK: - Pose Log Management
    
    func addPoseLogEntry(_ entry: PoseLogEntry) {
        poseLog.append(entry)
        savePoseLog()
    }
    
    func updatePoseLogEntry(_ entry: PoseLogEntry) {
        if let index = poseLog.firstIndex(where: { $0.id == entry.id }) {
            poseLog[index] = entry
            savePoseLog()
        }
    }
    
    func deletePoseLogEntry(_ entry: PoseLogEntry) {
        poseLog.removeAll { $0.id == entry.id }
        savePoseLog()
    }
    
    private func savePoseLog() {
        do {
            try DataManager.shared.save(poseLog, to: "poseLog.json")
        } catch {
            print("Error saving pose log: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    func getPoseById(_ id: UUID) -> Pose? {
        return poses.first { $0.id == id }
    }
    
    func getRoutineById(_ id: UUID) -> Routine? {
        return routines.first { $0.id == id }
    }
    
    func getPoseLogEntries(for poseId: UUID) -> [PoseLogEntry] {
        return poseLog.filter { $0.poseId == poseId }
    }
    
    func getRoutinesByCategory(_ category: String) -> [Routine] {
        return routines.filter { $0.category == category }
    }
    
    func getPosesByCategory(_ category: String) -> [Pose] {
        return poses.filter { $0.category == category }
    }
} 
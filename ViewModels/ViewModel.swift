import Foundation
import Combine
import FirebaseFirestore
import Vision


// MARK: - ViewModel
class ViewModel: ObservableObject {
    @Published var poses: [Pose] = []
    @Published var routines: [Routine] = []
    @Published var userProfile: UserProfile?
    @Published var poseLog: [PoseLogEntry] = []
    @Published var selectedRoutine: Routine?
    @Published var users: [UserProfile] = []
    private let db = Firestore.firestore()
    private var routinesListener: ListenerRegistration?

    private var cancellables = Set<AnyCancellable>()

    init() {
        print("🚀 ViewModel initialized - Instance: \(UUID().uuidString.prefix(8))")
        loadData()
        loadRoutines()
        seedRoutinesIfNeeded()
    }
    
    deinit {
        // Clean up Firebase listener
        routinesListener?.remove()
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
            if DataManager.shared.fileExists(fileName: "users.json") {
                users = try DataManager.shared.load([UserProfile].self, from: "users.json")
            }
        } catch {
            print("Error loading data: \(error)")
        }
    }

    private func loadRoutines() {
        // Prevent multiple listeners from being created
        guard routinesListener == nil else { 
            print("⚠️ Firebase listener already exists, skipping...")
            return 
        }
        
        print("🔍 Setting up Firebase routines listener...")
        routinesListener = db.collection("routines").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self,
                  let documents = snapshot?.documents else { return }

            print("📱 Firebase listener triggered with \(documents.count) routines")
            self.routines = documents.compactMap { document in
                try? Routine(from: document.data())
            }
        }
    }

    private func seedRoutinesIfNeeded() {
        // Only seed if we haven't already seeded and routines are empty
        // Use a UserDefaults flag to track if we've already seeded
        let hasSeeded = UserDefaults.standard.bool(forKey: "hasSeededRoutines")
        guard !hasSeeded else { 
            print("🌱 Routines already seeded, skipping...")
            return 
        }
        
        print("🌱 Seeding routines for the first time...")
        
        // Mark that we've seeded to prevent future seeding
        UserDefaults.standard.set(true, forKey: "hasSeededRoutines")
        
        // Example seeding (optional)
        let defaultRoutine = Routine(
            name: "Sample Routine",
            description: "This is a sample seeded routine.",
            category: "Core",
            poses: [],
            duration: 300,
            difficulty: 1,
            isUnlocked: true,
            xpReward: 50
        )

        if let data = defaultRoutine.asDictionary {
            db.collection("routines").document(defaultRoutine.id.uuidString).setData(data)
            print("✅ Seeded routine: \(defaultRoutine.name)")
        }
    }

    // MARK: - Save Users

    func saveUsers() {
        do {
            try DataManager.shared.save(users, to: "users.json")
        } catch {
            print("Error saving users: \(error)")
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

    // MARK: - Utility Helpers

    func getPoseById(_ id: UUID) -> Pose? {
        poses.first { $0.id == id }
    }

    func getRoutineById(_ id: UUID) -> Routine? {
        routines.first { $0.id == id }
    }

    func getPoseLogEntries(for poseId: UUID) -> [PoseLogEntry] {
        poseLog.filter { $0.poseId == poseId }
    }

    func getRoutinesByCategory(_ category: String) -> [Routine] {
        routines.filter { $0.category == category }
    }

    func getPosesByCategory(_ category: String) -> [Pose] {
        poses.filter { $0.category == category }
    }

    // MARK: - Accuracy Example (optional)

    func calculateRoutineAccuracy(_ routine: Routine) -> Double {
        let poseIds = Set(routine.poses.map { $0.id })
        let logs = poseLog.filter { poseIds.contains($0.poseId) }

        guard !logs.isEmpty else { return 0.0 }

        let accuracies = logs.map { Double($0.accuracyScore) / 100.0 }
        return accuracies.reduce(0, +) / Double(accuracies.count)
    }
}


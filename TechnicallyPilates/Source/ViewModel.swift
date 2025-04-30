import Foundation
import Combine
import SwiftUI
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class ViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var routines: [Routine] = []
    @Published var userProfile: UserProfile?
    @Published var poseLog: [PoseLogEntry] = []
    @Published var poseLabel: String = "Ready to start"
    @Published var poseColor: Color = .white
    @Published var startDetection: Bool = false
    @Published var repCount: Int = 0
    @Published var logEntries: [PoseLogEntry] = []
    @Published var consecutiveCorrectPoses: Int = 0
    @Published var selectedRoutine: Routine?
    @Published var currentPoseIndex: Int = 0
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    let session = AVCaptureSession()
    private var poseEstimator: PoseEstimator?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let db = Firestore.firestore()
    
    init() {
        // Initialize Firebase if it hasn't been initialized yet
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        setupAuthStateListener()
        loadInitialData()
        
        self.userProfile = UserProfile(
            name: "Default User",
            email: "default@example.com"
        )
        
        loadUserData()
        
        // Setup camera session
        setupCamera()
        
        loadData()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.loadUserProfile(userId: user.uid)
                } else {
                    self?.userProfile = nil
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let userId = result?.user.uid else { return }
            
            let newProfile = UserProfile(
                id: userId,
                name: name,
                email: email,
                level: 1,
                xp: 0,
                streakCount: 0,
                goals: [],
                achievements: [],
                unlockedAchievements: [],
                lastWorkoutDate: nil
            )
            
            self?.saveUserProfile(newProfile)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                if let data = try? document.data(as: UserProfile.self) {
                    DispatchQueue.main.async {
                        self?.userProfile = data
                    }
                }
            }
        }
    }
    
    func saveUserProfile(_ profile: UserProfile) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            try db.collection("users").document(userId).setData(from: profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        do {
            if DataManager.shared.fileExists(fileName: "exercises.json") {
                exercises = try DataManager.shared.load([Exercise].self, from: "exercises.json")
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
    
    func loadUserData() {
        // Load user data from persistent storage
    }
    
    func saveUserData() {
        // Save user data to persistent storage
    }
    
    // MARK: - Exercise Management
    
    func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
        saveExercises()
    }
    
    func updateExercise(_ exercise: Exercise) {
        if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
            exercises[index] = exercise
            saveExercises()
        }
    }
    
    func deleteExercise(_ exercise: Exercise) {
        exercises.removeAll { $0.id == exercise.id }
        saveExercises()
    }
    
    private func saveExercises() {
        do {
            try DataManager.shared.save(exercises, to: "exercises.json")
        } catch {
            print("Error saving exercises: \(error)")
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
        saveUserData()
    }
    
    // MARK: - Pose Log Management
    
    func addPoseLogEntry(_ entry: PoseLogEntry) {
        logEntries.append(entry)
        saveUserData()
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
    
    func getExerciseById(_ id: UUID) -> Exercise? {
        return exercises.first { $0.id == id }
    }
    
    func getRoutineById(_ id: UUID) -> Routine? {
        return routines.first { $0.id == id }
    }
    
    func getPoseLogEntries(for poseId: UUID) -> [PoseLogEntry] {
        return poseLog.filter { $0.poseId == poseId }
    }
    
    func getRoutinesByCategory(_ category: Category) -> [Routine] {
        return routines.filter { $0.category == category }
    }
    
    func getExercisesByCategory(_ category: Category) -> [Exercise] {
        return exercises.filter { $0.category == category }
    }
    
    private func setupCamera() {
        // Request camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.configureSession()
                    }
                }
            }
        default:
            break
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        
        // Initialize PoseEstimator
        poseEstimator = PoseEstimator(
            poseLabel: $poseLabel,
            poseColor: $poseColor,
            startDetection: $startDetection,
            repCount: $repCount,
            logEntries: $logEntries,
            onNewEntry: { [weak self] entry in
                self?.handleNewEntry(entry)
            },
            onComboBroken: { [weak self] in
                self?.handleComboBreak()
            }
        )
        
        // Start session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func togglePoseDetection() {
        startDetection.toggle()
    }
    
    private func handleNewEntry(_ entry: PoseLogEntry) {
        // Update user profile with XP
        userProfile?.addXP(entry.xpEarned)
        
        // Update consecutive correct poses
        if entry.accuracy >= 0.7 {
            consecutiveCorrectPoses += 1
        } else {
            consecutiveCorrectPoses = 0
        }
    }
    
    private func handleComboBreak() {
        consecutiveCorrectPoses = 0
    }
    
    func resetCombo() {
        // Reset the combo counter
    }
    
    func createCameraPreviewView() -> CameraPreviewView {
        CameraPreviewView(
            poseLabel: poseLabel,
            poseColor: poseColor,
            startDetection: startDetection,
            repCount: repCount,
            logEntries: logEntries,
            selectedRoutine: selectedRoutine ?? Routine(
                name: "Default Routine",
                description: "Default routine description",
                exercises: [],
                duration: 0,
                difficulty: .beginner,
                category: .strength
            ),
            currentPoseIndex: currentPoseIndex,
            onNewEntry: { [weak self] entry in
                self?.addPoseLogEntry(entry)
            },
            onComboBroken: { [weak self] in
                self?.resetCombo()
            }
        )
    }
    
    private func loadInitialData() {
        // Load any initial app data that doesn't require authentication
        // This could include default exercises, routines, etc.
    }
} 
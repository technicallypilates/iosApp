import Foundation
import Combine
import SwiftUI
import AVFoundation
import FirebaseAuth
import FirebaseFirestore

class ViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var poseLabel = "Ready to start"
    @Published var poseColor: Color = .white
    @Published var startDetection = false
    @Published var repCount = 0
    @Published var exercises: [Exercise] = []
    @Published var routines: [Routine] = []
    @Published var poseLog: [PoseLogEntry] = []
    @Published var selectedRoutine: Routine?
    @Published var currentPoseIndex: Int = 0
    @Published var logEntries: [PoseLogEntry] = []
    @Published var consecutiveCorrectPoses = 0
    @Published var errorMessage: String?

    let session = AVCaptureSession()
    private var poseEstimator: PoseEstimator?
    private let db = Firestore.firestore()

    init() {
        // Do nothing until user logs in
    }

    func onLogin(user: UserProfile) {
        self.userProfile = user
        loadUserData()
        loadInitialData()
        setupCamera()
        loadData()
    }

    private func loadInitialData() {}
    func loadUserData() {}
    func saveUserData() {}

    func updateUserProfile(to updated: UserProfile) {
        userProfile = updated
        saveUserData()
    }

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
            print("Error loading local data: \(error)")
        }
    }

    private func setupCamera() {
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

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        poseEstimator = PoseEstimator(
            poseLabel: poseLabelBinding,
            poseColor: poseColorBinding,
            startDetection: startDetectionBinding,
            repCount: repCountBinding,
            onNewEntry: { [weak self] entry in
                DispatchQueue.main.async {
                    self?.addPoseLogEntry(entry)
                }
            },
            onComboBroken: { [weak self] in
                DispatchQueue.main.async {
                    self?.resetCombo()
                }
            }
        )

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func resetCombo() {
        consecutiveCorrectPoses = 0
    }

    func addPoseLogEntry(_ entry: PoseLogEntry) {
        logEntries.append(entry)
        saveUserData()
    }

    func getExerciseById(_ id: UUID) -> Exercise? {
        exercises.first { $0.id == id }
    }
    
    // In ViewModel.swift

    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        saveUserData()
    }

    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        saveUserData()
    }


    // Bindings
    var poseLabelBinding: Binding<String> {
        Binding(get: { self.poseLabel }, set: { self.poseLabel = $0 })
    }

    var poseColorBinding: Binding<Color> {
        Binding(get: { self.poseColor }, set: { self.poseColor = $0 })
    }

    var startDetectionBinding: Binding<Bool> {
        Binding(get: { self.startDetection }, set: { self.startDetection = $0 })
    }

    var repCountBinding: Binding<Int> {
        Binding(get: { self.repCount }, set: { self.repCount = $0 })
    }
}


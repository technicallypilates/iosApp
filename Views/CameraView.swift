import SwiftUI
import AVFoundation
import Vision
import Foundation
import UIKit

struct PoseCorrectionView: View {
    let corrections: [PoseCorrection]
    
    var body: some View {
        VStack {
            if let mainCorrection = corrections.first {
                CorrectionCard(correction: mainCorrection)
            }
            
            if corrections.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(corrections.dropFirst()) { correction in
                            CorrectionCard(correction: correction)
                                .frame(width: 200)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct CorrectionCard: View {
    let correction: PoseCorrection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(severityColor)
                Text(correction.message)
                    .font(.headline)
            }
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: correction.severity)
                .tint(severityColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private var iconName: String {
        switch correction.type {
        case .alignment: return "arrow.up.and.down.and.arrow.left.and.right"
        case .angle: return "angle"
        case .stability: return "waveform.path"
        case .symmetry: return "arrow.left.and.right"
        }
    }
    
    private var severityColor: Color {
        switch correction.severity {
        case 0.0..<0.3: return .green
        case 0.3..<0.7: return .yellow
        default: return .red
        }
    }
    
    private var subtitle: String {
        switch correction.type {
        case .alignment: return "Body alignment needs adjustment"
        case .angle: return "Joint angle correction needed"
        case .stability: return "Hold the pose more steadily"
        case .symmetry: return "Balance your body position"
        }
    }
}

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Binding var isActive: Bool
    @Binding var currentPose: String?
    @State private var currentCorrections: [PoseCorrection] = []
    @State private var poseLabel: String = ""
    @State private var poseColor: Color = .green
    @State private var startDetection: Bool = false
    @State private var repCount: Int = 0
    @State private var logEntries: [PoseLogEntry] = []
    @State private var poseAccuracy: Double = 0.0
    @State private var selectedRoutine: Routine = Routine(
        name: "Default",
        description: "Default routine",
        category: "Default",
        poses: [],
        duration: 0,
        difficulty: 1
    )
    @State private var currentPoseIndex: Int = 0
    @State private var showXPToast: Bool = false
    @State private var xpGained: Int = 0
    @State private var showConfetti: Bool = false
    @State private var showDifficultyInfo: Bool = false

    var body: some View {
        ZStack {
            CameraPreviewView(
                poseLabel: $poseLabel,
                poseColor: $poseColor,
                startDetection: $startDetection,
                repCount: $repCount,
                logEntries: $logEntries,
                poseAccuracy: $poseAccuracy,
                currentCorrections: $currentCorrections,
                selectedRoutine: selectedRoutine,
                currentPoseIndex: currentPoseIndex,
                onNewEntry: { entry in
                    // Calculate XP gain using difficulty multiplier
                    let accuracy = Double(entry.accuracyScore) / 100.0
                    let baseXP = 10.0
                    let difficulty = viewModel.poseCorrectionSystem.getCurrentDifficulty()
                    let gained = Int(baseXP * accuracy * difficulty.xpMultiplier)
                    xpGained = gained
                    showXPToast = true
                    showConfetti = true
                    // Hide toast after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showXPToast = false
                        showConfetti = false
                    }
                },
                onComboBroken: {
                    // Handle combo broken
                }
            )
            .overlay(
                Group {
                    if viewModel.isPoseDetectionActive && !currentCorrections.isEmpty {
                        PoseCorrectionView(corrections: currentCorrections)
                            .padding()
                    }
                }
            )
            
            VStack {
                HStack {
                    Button(action: {
                        isActive = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showDifficultyInfo.toggle()
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Button(action: {
                        viewModel.togglePoseDetection()
                    }) {
                        Image(systemName: viewModel.isPoseDetectionActive ? "figure.walk" : "figure.stand")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
            }
            
            // Difficulty Info Overlay
            if showDifficultyInfo {
                VStack {
                    let difficulty = viewModel.poseCorrectionSystem.getCurrentDifficulty()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Difficulty Level")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Tolerance:")
                            Spacer()
                            Text("±\(String(format: "%.1f", difficulty.baseTolerance))°")
                        }
                        .foregroundColor(.white)
                        
                        HStack {
                            Text("Required Accuracy:")
                            Spacer()
                            Text("\(Int(difficulty.requiredAccuracy * 100))%")
                        }
                        .foregroundColor(.white)
                        
                        HStack {
                            Text("XP Multiplier:")
                            Spacer()
                            Text("\(String(format: "%.1f", difficulty.xpMultiplier))x")
                        }
                        .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // XP Toast
            if showXPToast {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("+\(xpGained) XP!")
                            .font(.title2)
                            .bold()
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.yellow)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                        Spacer()
                    }
                    .padding(.bottom, 60)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Confetti
            if showConfetti {
                ConfettiView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            viewModel.checkPermissions()
            if let pose = currentPose {
                viewModel.setCurrentPose(pose)
            }
        }
        .onChange(of: viewModel.currentCorrections) { newCorrections in
            currentCorrections = newCorrections
        }
    }
}

class CameraViewModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isPoseDetectionActive = false
    @Published var currentCorrections: [PoseCorrection] = []
    
    private let poseDetectionQueue = DispatchQueue(label: "com.technicallypilates.poseDetection")
    let poseCorrectionSystem = PoseCorrectionSystem()
    private var currentPose: String?
    
    func checkPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("🔐 Camera authorization status: \(status.rawValue)") // 3 = authorized

        switch status {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    print("🔐 Camera permission granted: \(granted)")
                    if granted {
                        self?.setupCamera()
                    } else {
                        print("❌ User denied camera access.")
                    }
                }
            }
        case .denied, .restricted:
            print("❌ Camera access denied or restricted.")
        @unknown default:
            print("❓ Unknown camera authorization status.")
        }
    }

    
    func setCurrentPose(_ pose: String) {
        currentPose = pose
        poseCorrectionSystem.setCurrentPose(pose)
    }
    
    func setUserProfile(_ profile: UserProfile) {
        poseCorrectionSystem.setUserProfile(profile)
    }
    
    func togglePoseDetection() {
        isPoseDetectionActive.toggle()
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            return
        }
        
        session.addInput(videoInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: poseDetectionQueue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isPoseDetectionActive,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
            
            if let observation = request.results?.first as? VNHumanBodyPoseObservation {
                let corrections = poseCorrectionSystem.analyzePose(observation)
                
                DispatchQueue.main.async {
                    self.currentCorrections = corrections
                }
            }
        } catch {
            print("Error performing pose detection: \(error)")
        }
    }
}

struct CameraPermissionView: View {
    let status: AVAuthorizationStatus
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(status == .denied ? "Camera Access Denied" : "Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)

            Text(status == .denied ?
                 "Please enable camera access in Settings to use pose detection" :
                 "We need camera access to monitor your Pilates poses")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            if status == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Button("Allow Camera Access") {
                    onRequestPermission()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}


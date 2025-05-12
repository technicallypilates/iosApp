import SwiftUI
import AVFoundation
import Vision
import UIKit

struct CameraView: View {
    @Binding var poseLabel: String
    @Binding var poseColor: Color
    @Binding var startDetection: Bool
    @Binding var repCount: Int
    @Binding var logEntries: [PoseLogEntry]
    @Binding var poseAccuracy: Double // ✅ NEW

    var selectedRoutine: Routine
    var currentPoseIndex: Int
    var onNewEntry: (PoseLogEntry) -> Void

    @State private var comboCount = 0
    @State private var showComboText = false
    @State private var comboTitle = ""
    @State private var showMedal = false
    @State private var sparkleAnimation = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined

    private var isCameraAuthorized: Bool {
        cameraPermissionStatus == .authorized
    }

    var body: some View {
        ZStack {
            #if targetEnvironment(simulator)
            Color.clear
            #else
            if isCameraAuthorized {
                CameraPreviewView(
                    poseLabel: $poseLabel,
                    poseColor: $poseColor,
                    startDetection: $startDetection,
                    repCount: $repCount,
                    logEntries: $logEntries,
                    poseAccuracy: $poseAccuracy, // ✅ PASS NEW BINDING
                    selectedRoutine: selectedRoutine,
                    currentPoseIndex: currentPoseIndex,
                    onNewEntry: { entry in
                        onNewEntry(entry)
                        handleComboSuccess()
                    },
                    onComboBroken: handleComboBreak
                )
                .overlay(
                    Group {
                        if showComboText {
                            Text(comboTitle)
                                .font(.title)
                                .foregroundColor(comboCount > 0 ? .green : .red)
                                .transition(.scale)
                        }
                        if showMedal {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                                .scaleEffect(sparkleAnimation ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5), value: sparkleAnimation)
                        }
                    }
                )
            } else {
                CameraPermissionView(status: cameraPermissionStatus) {
                    requestCameraPermission()
                }
            }
            #endif
        }
        .onAppear {
            checkCameraPermission()
        }
    }

    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraPermissionStatus = granted ? .authorized : .denied
            }
        }
    }

    private func handleComboSuccess() {
        comboCount += 1
        showComboText = true
        comboTitle = "Combo x\(comboCount)!"
        showMedal = true
        sparkleAnimation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showComboText = false
            showMedal = false
            sparkleAnimation = false
        }
    }

    private func handleComboBreak() {
        comboCount = 0
        showComboText = true
        comboTitle = "Combo Broken!"
        showMedal = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showComboText = false
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


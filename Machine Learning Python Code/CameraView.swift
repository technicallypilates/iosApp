//  CameraView.swift

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

    var selectedRoutine: Routine
    var currentPoseIndex: Int
    var onNewEntry: (PoseLogEntry) -> Void

    @State private var comboCount = 0
    @State private var showComboText = false
    @State private var comboTitle = ""
    @State private var showMedal = false
    @State private var sparkleAnimation = false

    var body: some View {
        ZStack {
            CameraPreviewView(
                poseLabel: $poseLabel,
                poseColor: $poseColor,
                startDetection: $startDetection,
                repCount: $repCount,
                logEntries: $logEntries,
                selectedRoutine: selectedRoutine,
                currentPoseIndex: currentPoseIndex,
                onNewEntry: { entry in
                    onNewEntry(entry)
                    handleComboSuccess()
                },
                onComboBroken: handleComboBreak
            )

            if !startDetection {
                VStack {
                    Text("📷 Camera will activate when you tap Start Detection")
                        .foregroundColor(.gray)
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(12)
                }
            }

            VStack {
                Spacer()
                VStack(spacing: 12) {
                    ZStack {
                        if sparkleAnimation {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 140, height: 140)
                                .scaleEffect(sparkleAnimation ? 1.2 : 0.8)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: sparkleAnimation)
                        }

                        Text("Pose: \(poseLabel)")
                            .font(.title.bold())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(poseColor.opacity(0.8))
                            .cornerRadius(20)
                            .padding(.horizontal)
                            .shadow(color: poseColor.opacity(0.7), radius: 15) // Glow effect
                            .animation(.easeInOut(duration: 0.5), value: poseColor)
                    }

                    Text("Reps: \(repCount)")
                        .font(.title2.bold())
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(16)
                }

                if showComboText {
                    Text(comboTitle)
                        .font(.largeTitle.bold())
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .transition(.scale)
                        .animation(.easeOut, value: showComboText)
                        .padding(.top)
                }

                if showMedal {
                    Image(systemName: "medal.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.yellow)
                        .transition(.scale)
                        .animation(.spring(), value: showMedal)
                        .padding(.top)
                }

                Spacer()
            }
        }
        .onAppear {
            sparkleAnimation = true
        }
    }

    private func handleComboSuccess() {
        comboCount += 1

        if comboCount % 5 == 0 {
            comboTitle = titleForCombo(comboCount)
            showComboText = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showComboText = false
            }
            playChimeSound()
        }

        if comboCount % 10 == 0 {
            showMedal = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showMedal = false
            }
        }
    }

    private func handleComboBreak() {
        if comboCount > 0 {
            AudioServicesPlaySystemSound(1104) // Sad sound
        }
        comboCount = 0
    }

    private func titleForCombo(_ count: Int) -> String {
        switch count {
        case 5: return "Nice Streak! 🌟"
        case 10: return "On Fire! 🔥"
        case 20: return "Unstoppable!! 🚀"
        default: return "Combo x\(count)!"
        }
    }

    private func playChimeSound() {
        AudioServicesPlaySystemSound(1025) // Success chime
    }
}

// MARK: - CameraPreviewView (Coordinator updated)

struct CameraPreviewView: UIViewRepresentable {
    @Binding var poseLabel: String
    @Binding var poseColor: Color
    @Binding var startDetection: Bool
    @Binding var repCount: Int
    @Binding var logEntries: [PoseLogEntry]

    var selectedRoutine: Routine
    var currentPoseIndex: Int
    var onNewEntry: (PoseLogEntry) -> Void
    var onComboBroken: () -> Void

    let speechCoach = SpeechCoach()

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return view }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(output)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)

        session.startRunning()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> CameraCoordinator {
        return CameraCoordinator(parent: self)
    }

    class CameraCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraPreviewView
        let poseEstimator = PoseEstimator()
        var lastPoseLabel: String = ""
        var isPoseHeld = false
        var holdFrameCount = 0

        init(parent: CameraPreviewView) {
            self.parent = parent
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard parent.startDetection,
                  let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            poseEstimator.performPoseDetection(pixelBuffer: pixelBuffer) { observations, predictedLabel in
                guard observations.first != nil else { return }

                DispatchQueue.main.async {
                    guard let label = predictedLabel else {
                        self.parent.poseLabel = "Analyzing..."
                        self.parent.poseColor = .gray
                        self.resetState()
                        return
                    }

                    self.parent.poseLabel = label
                    let expectedPose = self.parent.selectedRoutine.poses[self.parent.currentPoseIndex].name

                    if label.lowercased().contains("correct") && label.lowercased().contains(expectedPose.lowercased()) {

                        self.parent.poseColor = .green

                        if label == self.lastPoseLabel {
                            self.holdFrameCount += 1

                            if self.holdFrameCount >= 10 && !self.isPoseHeld {
                                self.parent.repCount += 1
                                self.isPoseHeld = true

                                let newEntry = PoseLogEntry(
                                    routine: self.parent.selectedRoutine.rawValue,
                                    pose: label,
                                    timestamp: Date(),
                                    repsCompleted: self.parent.repCount
                                )
                                self.parent.logEntries.append(newEntry)
                                self.parent.speechCoach.speak("Good job!")
                                self.parent.onNewEntry(newEntry)
                            }
                        } else {
                            self.resetHold()
                        }
                    } else {
                        self.parent.poseColor = .red
                        self.parent.onComboBroken()
                        self.triggerVibration()
                        self.resetHold()
                    }

                    self.lastPoseLabel = label
                }
            }
        }

        private func resetHold() {
            holdFrameCount = 0
            isPoseHeld = false
        }

        private func resetState() {
            resetHold()
            lastPoseLabel = ""
        }

        private func triggerVibration() {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}


import Foundation
import AVFoundation
import Vision
import SwiftUI

class PoseEstimator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Binding var poseLabel: String
    @Binding var poseColor: Color
    @Binding var startDetection: Bool
    @Binding var repCount: Int
    @Binding var logEntries: [PoseLogEntry]

    var onNewEntry: (PoseLogEntry) -> Void
    var onComboBroken: () -> Void

    var selectedRoutine: Routine = Routine(name: "Default", poses: [])
    var currentPoseIndex: Int = 0

    var captureSession = AVCaptureSession()
    private var lastLabel: String?
    private var correctStreak = 0
    private var isCameraSetup = false

    init(poseLabel: Binding<String>,
         poseColor: Binding<Color>,
         startDetection: Binding<Bool>,
         repCount: Binding<Int>,
         logEntries: Binding<[PoseLogEntry]>,
         onNewEntry: @escaping (PoseLogEntry) -> Void,
         onComboBroken: @escaping () -> Void) {

        self._poseLabel = poseLabel
        self._poseColor = poseColor
        self._startDetection = startDetection
        self._repCount = repCount
        self._logEntries = logEntries
        self.onNewEntry = onNewEntry
        self.onComboBroken = onComboBroken

        super.init()
    }

    func setupCaptureSession() {
        guard !isCameraSetup else { return }
        
        print("🔄 Setting up camera session...")
        captureSession.beginConfiguration()

        // Try front camera first
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video, position: .front) {
            print("📱 Front camera found")
            setupCameraInput(device: videoDevice)
        } else if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: .video, position: .back) {
            print("📱 Using back camera as fallback")
            setupCameraInput(device: videoDevice)
        } else {
            print("❌ No camera available")
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            print("✅ Added video output")
        } else {
            print("❌ Could not add video output")
            return
        }

        captureSession.commitConfiguration()
        isCameraSetup = true
        print("✅ Camera setup complete")
    }

    private func setupCameraInput(device: AVCaptureDevice) {
        do {
            let videoInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                print("✅ Added camera input")
            } else {
                print("❌ Could not add camera input")
            }
        } catch {
            print("❌ Error setting up camera input: \(error.localizedDescription)")
        }
    }

    func startSession() {
        setupCaptureSession()
        
        if !captureSession.isRunning {
            print("▶️ Starting camera session...")
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
                print("✅ Camera session started")
            }
        }
    }

    func updateState(startDetection: Bool, selectedRoutine: Routine, currentPoseIndex: Int) {
        self.startDetection = startDetection
        self.selectedRoutine = selectedRoutine
        self.currentPoseIndex = currentPoseIndex
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard startDetection,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        performPoseDetection(pixelBuffer: pixelBuffer, mirrorIfNeeded: true) { [weak self] observations, label in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let label = label {
                    self.poseLabel = label
                    self.poseColor = label.starts(with: "correct") ? .green : .red

                    if label.starts(with: "correct") {
                        if label != self.lastLabel {
                            self.repCount += 1
                            print("✅ Correct pose detected: \(label)")

                            let entry = PoseLogEntry(
                                routine: self.selectedRoutine.name,
                                pose: self.selectedRoutine.poses[safe: self.currentPoseIndex]?.name ?? "Unknown",
                                timestamp: Date(),
                                repsCompleted: 1
                            )

                            self.logEntries.append(entry)
                            self.onNewEntry(entry)
                        }
                        self.correctStreak += 1
                    } else {
                        if self.correctStreak > 0 {
                            self.onComboBroken()
                        }
                        self.correctStreak = 0
                        print("❌ Incorrect pose detected: \(label)")
                    }

                    self.lastLabel = label
                } else {
                    print("⚠️ No pose detected in frame")
                }
            }
        }
    }

    private func performPoseDetection(pixelBuffer: CVPixelBuffer, mirrorIfNeeded: Bool, completion: @escaping ([VNHumanBodyPoseObservation]?, String?) -> Void) {
        let request = VNDetectHumanBodyPoseRequest()
        request.usesCPUOnly = false

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
            
            guard let results = request.results as? [VNHumanBodyPoseObservation],
                  !results.isEmpty else {
                completion(nil, nil)
                return
            }
            
            // For now, use a dummy label - replace with actual ML model prediction
            let label = "correct_\(selectedRoutine.poses[safe: currentPoseIndex]?.name ?? "unknown")"
            completion(results, label)
            
        } catch {
            print("❌ Error performing pose detection: \(error.localizedDescription)")
            completion(nil, nil)
        }
    }
}

// Safe index helper
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}



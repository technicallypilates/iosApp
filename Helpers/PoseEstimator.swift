import AVFoundation
import Vision
import UIKit
import SwiftUI
import CoreML
import Foundation

class PoseEstimator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Binding private var poseLabel: String
    @Binding private var poseColor: Color
    @Binding private var startDetection: Bool
    @Binding private var repCount: Int
    @Binding private var logEntries: [PoseLogEntry]
    @Binding private var poseAccuracy: Double
    @Binding private var currentCorrections: [PoseCorrection]

    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInteractive)
    var captureSession: AVCaptureSession?

    private var selectedRoutine: Routine?
    private var currentPoseIndex: Int = 0
    private var onNewEntry: (PoseLogEntry) -> Void
    private var onComboBroken: () -> Void

    private var model: PoseClassifier?
    private let poseCorrectionSystem = PoseCorrectionSystem()

    private let frameProcessingInterval: TimeInterval = 0.2
    private let poseConfidenceThreshold: Int = 60
    private var lastProcessedTime = Date.distantPast

    var poseBaselines: [UUID: [String: Double]]

    private var previousLeftHip: VNRecognizedPoint?

    init(poseLabel: Binding<String>,
         poseColor: Binding<Color>,
         startDetection: Binding<Bool>,
         repCount: Binding<Int>,
         logEntries: Binding<[PoseLogEntry]>,
         poseAccuracy: Binding<Double>,
         currentCorrections: Binding<[PoseCorrection]>,
         onNewEntry: @escaping (PoseLogEntry) -> Void,
         onComboBroken: @escaping () -> Void,
         poseBaselines: [UUID: [String: Double]] = [:]) {
        _poseLabel = poseLabel
        _poseColor = poseColor
        _startDetection = startDetection
        _repCount = repCount
        _logEntries = logEntries
        _poseAccuracy = poseAccuracy
        _currentCorrections = currentCorrections
        self.onNewEntry = onNewEntry
        self.onComboBroken = onComboBroken
        self.poseBaselines = poseBaselines
        super.init()
        loadModel()
    }

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            self.model = try PoseClassifier(configuration: config)
        } catch {
            print("⚠️ Failed to load PoseClassifier:", error)
        }
    }

    func startSession() {
        let session = AVCaptureSession()
        session.beginConfiguration()

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("❌ Failed to access camera input.")
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }

        if let connection = videoDataOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        session.commitConfiguration()
        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            print("✅ Camera session started.")
        }
    }

    func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
        print("🔁 Capture session stopped.")
    }

    func updateState(startDetection: Bool, selectedRoutine: Routine, currentPoseIndex: Int) {
        self.startDetection = startDetection
        self.selectedRoutine = selectedRoutine
        self.currentPoseIndex = currentPoseIndex
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard startDetection,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let selectedRoutine = selectedRoutine else { return }

        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= frameProcessingInterval else { return }
        lastProcessedTime = now

        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                return
            }
            self.handlePoseObservation(observation, for: selectedRoutine.poses[self.currentPoseIndex])
        }

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:]).perform([request])
    }

    private func handlePoseObservation(_ observation: VNHumanBodyPoseObservation, for expectedPose: Pose) {
        do {
            guard let recognizedPoints = try? observation.recognizedPoints(.all) else { return }
            let liveAngles = calculateLiveAngles(from: recognizedPoints)
            guard let baseline = poseBaselines[expectedPose.id] else {
                print("⚠️ No baseline available for pose '\(expectedPose.name)'")
                return
            }

            // Compute velocities
            let currentLeftHip = recognizedPoints[.leftHip]
            var velocityX: Double = 0
            var velocityY: Double = 0
            var velocityZ: Double = 0 // Placeholder for 2D

            if let previous = previousLeftHip, let current = currentLeftHip {
                velocityX = Double(current.location.x - previous.location.x)
                velocityY = Double(current.location.y - previous.location.y)
            }
            previousLeftHip = currentLeftHip

            // Append velocity to angles
            var features = liveAngles
            features["velocityX"] = velocityX
            features["velocityY"] = velocityY
            features["velocityZ"] = velocityZ

            // Use weighted accuracy calculation
            let weightedAccuracy = poseCorrectionSystem.computeWeightedAccuracy(liveAngles: liveAngles, baseline: baseline)
            let accuracyScore = Int(weightedAccuracy)

            let corrections = poseCorrectionSystem.analyzePose(observation)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.poseAccuracy = Double(accuracyScore) / 100.0
                self.currentCorrections = corrections

                if accuracyScore >= self.poseConfidenceThreshold {
                    self.poseLabel = expectedPose.name
                    self.poseColor = .green
                    self.repCount += 1
                    var jointAccuracies: [String: Double] = [:]
                    for (joint, liveValue) in liveAngles {
                        if let target = baseline[joint] {
                            let error = abs(liveValue - target)
                            let tolerance = 15.0
                            let score = max(0.0, 1.0 - (error / tolerance))
                            jointAccuracies[joint] = score
                        }
                    }
                    let entry = PoseLogEntry(
                        poseId: expectedPose.id,
                        routineId: self.selectedRoutine?.id ?? UUID(),
                        repsCompleted: self.repCount,
                        accuracyScore: accuracyScore,
                        timestamp: Date(),
                        jointAccuracies: jointAccuracies
                    )
                    self.logEntries.append(entry)
                    self.onNewEntry(entry)
                } else {
                    self.poseLabel = "Incorrect Pose"
                    self.poseColor = .red
                    self.onComboBroken()
                }
            }
        } catch {
            print("⚠️ Angle extraction or prediction failed:", error)
        }
    }

    private func calculateLiveAngles(from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> [String: Double] {
        func angle(between a: VNRecognizedPoint, _ b: VNRecognizedPoint, _ c: VNRecognizedPoint) -> Double {
            let ab = CGVector(dx: a.location.x - b.location.x, dy: a.location.y - b.location.y)
            let cb = CGVector(dx: c.location.x - b.location.x, dy: c.location.y - b.location.y)
            let dot = ab.dx * cb.dx + ab.dy * cb.dy
            let mag = hypot(ab.dx, ab.dy) * hypot(cb.dx, cb.dy)
            guard mag > 0 else { return 0 }
            let cosAngle = max(min(dot / mag, 1.0), -1.0)
            return acos(cosAngle) * 180 / Double.pi
        }

        return [
            "leftHipAngle": angle(between: points[.leftShoulder]!, points[.leftHip]!, points[.leftKnee]!),
            "rightHipAngle": angle(between: points[.rightShoulder]!, points[.rightHip]!, points[.rightKnee]!),
            "leftElbowAngle": angle(between: points[.leftShoulder]!, points[.leftElbow]!, points[.leftWrist]!),
            "rightElbowAngle": angle(between: points[.rightShoulder]!, points[.rightElbow]!, points[.rightWrist]!),
            "leftKneeAngle": angle(between: points[.leftHip]!, points[.leftKnee]!, points[.leftAnkle]!),
            "rightKneeAngle": angle(between: points[.rightHip]!, points[.rightKnee]!, points[.rightAnkle]!)
        ]
    }
}

// MARK: - Baseline Loader
extension PoseEstimator {
    static func loadBaselineAngles(from filename: String = "FullRollUp_baseline_angles.json") -> [UUID: [String: Double]] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Double]] else {
            print("⚠️ Failed to load baseline angles from \(filename)")
            return [:]
        }

        var result: [UUID: [String: Double]] = [:]
        for (key, angles) in raw {
            if let uuid = UUID(uuidString: key) {
                result[uuid] = angles
            }
        }
        return result
    }
}



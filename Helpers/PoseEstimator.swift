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

    private var model: PoseClassifierSequence?
    private let poseCorrectionSystem = PoseCorrectionSystem()

    private let frameProcessingInterval: TimeInterval = 0.2
    private let poseConfidenceThreshold: Int = 60
    private var lastProcessedTime = Date.distantPast

    var poseBaselines: [UUID: [String: Double]]
    private var previousLeftHip: VNRecognizedPoint?

    // MARK: - Init
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
        print("[PoseEstimator] Initialized")
    }

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            self.model = try PoseClassifierSequence(configuration: config)
            print("✅ PoseClassifier model loaded.")
        } catch {
            print("❌ Failed to load PoseClassifier:", error)
        }
    }

    // MARK: - Camera Setup
    func startSession() {
        print("[PoseEstimator] Starting capture session")
        let session = AVCaptureSession()
        session.beginConfiguration()

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ No available video device.")
            return
        }

        print("✅ Using camera: \(videoDevice.localizedName)")

        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("❌ Failed to create AVCaptureDeviceInput.")
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
            print("✅ Added video input to session.")
        } else {
            print("❌ Could not add video input.")
        }

        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            print("✅ Added video output to session.")
        } else {
            print("❌ Could not add video output.")
        }

        if let connection = videoDataOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
            print("✅ Set video orientation to portrait.")
        }

        session.commitConfiguration()
        self.captureSession = session

        NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionRuntimeError,
            object: session,
            queue: .main
        ) { notification in
            print("❌ AVCaptureSession runtime error:", notification)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.captureSession?.startRunning()
            print("🎥 Attempted to start capture session.")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let isRunning = self.captureSession?.isRunning ?? false
                print("🎥 Confirmed on main thread: session running = \(isRunning)")
                print("🧪 Inputs: \(session.inputs.count), Outputs: \(session.outputs.count)")
            }
        }
    }

    func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
        print("🛑 Capture session stopped.")
    }

    func updateState(startDetection: Bool, selectedRoutine: Routine, currentPoseIndex: Int) {
        print("🔄 updateState called: startDetection=\(startDetection), currentPoseIndex=\(currentPoseIndex), routine=\(selectedRoutine.name)")
        DispatchQueue.main.async {
            self.startDetection = startDetection
            self.selectedRoutine = selectedRoutine
            self.currentPoseIndex = currentPoseIndex
        }
    }

    // MARK: - Frame Processing
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        print("[PoseEstimator] Received frame")
        guard startDetection,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let selectedRoutine = selectedRoutine else {
            return
        }

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

        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:]).perform([request])
        } catch {
            print("❌ Vision request failed:", error)
        }
    }

    private func handlePoseObservation(_ observation: VNHumanBodyPoseObservation, for expectedPose: Pose) {
        do {
            guard let recognizedPoints = try? observation.recognizedPoints(.all) else { return }
            let liveAngles = calculateLiveAngles(from: recognizedPoints)

            print("[PoseEstimator] Live angles for \(expectedPose.name):")
            for (joint, angle) in liveAngles {
                print(" - \(joint): \(String(format: "%.2f", angle))°")
            }

            guard let baseline = poseBaselines[expectedPose.id] else {
                print("⚠️ No baseline available for pose '\(expectedPose.name)'")
                return
            }

            let currentLeftHip = recognizedPoints[.leftHip]
            var velocityX: Double = 0, velocityY: Double = 0, velocityZ: Double = 0
            if let previous = previousLeftHip, let current = currentLeftHip {
                velocityX = Double(current.location.x - previous.location.x)
                velocityY = Double(current.location.y - previous.location.y)
            }
            previousLeftHip = currentLeftHip

            var features = liveAngles
            features["velocityX"] = velocityX
            features["velocityY"] = velocityY
            features["velocityZ"] = velocityZ

            let weightedAccuracy = poseCorrectionSystem.computeWeightedAccuracy(liveAngles: liveAngles, baseline: baseline)
            let accuracyScore = Int(weightedAccuracy)
            
            print("[PoseEstimator] Total pose accuracy = \(accuracyScore)%")

            let corrections = poseCorrectionSystem.analyzePose(observation)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.poseAccuracy = Double(accuracyScore) / 100.0
                self.currentCorrections = corrections

                if accuracyScore >= self.poseConfidenceThreshold {
                    self.poseLabel = expectedPose.name
                    self.poseColor = .green
                    self.repCount += 1

                    print("[PoseEstimator] Comparison to baseline:")
                    var jointAccuracies: [String: Double] = [:]
                    for (joint, liveValue) in liveAngles {
                        if let target = baseline[joint] {
                            let error = abs(liveValue - target)
                            let tolerance = 15.0 // Can be customized per joint
                            let score = max(0.0, 1.0 - (error / tolerance))
                            jointAccuracies[joint] = score
                            let percent = Int(score * 100)
                            print(" - \(joint): Live = \(String(format: "%.2f", liveValue))°, Target = \(target)°, Accuracy = \(percent)%")
                        } else {
                            print(" - ⚠️ No baseline for \(joint)")
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
                    print("[PoseEstimator] Pose detected: \(expectedPose.name)")
                } else {
                    self.poseLabel = "Incorrect Pose"
                    self.poseColor = .red
                    self.onComboBroken()
                    print("❌ Pose not recognized. Accuracy: \(accuracyScore)%")
                }
            }
        } catch {
            print("⚠️ Error handling pose observation:", error)
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

        func alignmentAngle(between a: VNRecognizedPoint, and b: VNRecognizedPoint) -> Double {
            let dy = a.location.y - b.location.y
            let dx = a.location.x - b.location.x
            return atan2(dy, dx) * 180 / .pi
        }

        var angles: [String: Double] = [
            "leftHipAngle": angle(between: points[.leftShoulder]!, points[.leftHip]!, points[.leftKnee]!),
            "rightHipAngle": angle(between: points[.rightShoulder]!, points[.rightHip]!, points[.rightKnee]!),
            "leftElbowAngle": angle(between: points[.leftShoulder]!, points[.leftElbow]!, points[.leftWrist]!),
            "rightElbowAngle": angle(between: points[.rightShoulder]!, points[.rightElbow]!, points[.rightWrist]!),
            "leftKneeAngle": angle(between: points[.leftHip]!, points[.leftKnee]!, points[.leftAnkle]!),
            "rightKneeAngle": angle(between: points[.rightHip]!, points[.rightKnee]!, points[.rightAnkle]!)
        ]

        if let root = points[.root], let neck = points[.neck] {
            let vector = CGVector(dx: neck.location.x - root.location.x,
                                  dy: neck.location.y - root.location.y)
            let angle = atan2(vector.dy, vector.dx) * 180 / .pi
            angles["spineAngle"] = angle
        }

        if let left = points[.leftShoulder], let right = points[.rightShoulder] {
            angles["shoulderAlignment"] = alignmentAngle(between: left, and: right)
        }

        if let left = points[.leftHip], let right = points[.rightHip] {
            angles["hipAlignment"] = alignmentAngle(between: left, and: right)
        }

        return angles
    }

    // MARK: - Baseline Loader
    static func loadBaselineAngles(from filename: String = "baseline_angles_sequence.json") -> [UUID: [String: Double]] {
        let baseName = filename.replacingOccurrences(of: ".json", with: "")
        
        guard let url = Bundle.main.url(forResource: baseName, withExtension: "json") else {
            print("⚠️ Could not locate file: \(filename)")
            return [:]
        }
        
        do {
            let data = try Data(contentsOf: url)
            guard let raw = try JSONSerialization.jsonObject(with: data) as? [String: [String: Double]] else {
                print("⚠️ File structure is invalid for baseline angles in \(filename)")
                return [:]
            }

            var result: [UUID: [String: Double]] = [:]
            for (key, angles) in raw {
                if let uuid = UUID(uuidString: key) {
                    result[uuid] = angles
                    print("✅ Loaded baseline for pose ID: \(uuid)")
                } else {
                    print("❌ Invalid UUID string in baseline JSON: \(key)")
                }
            }
            print("✅ Loaded \(result.count) baseline pose(s) from \(filename)")
            return result
        } catch {
            print("❌ Error loading or parsing \(filename):", error)
            return [:]
        }
    }
}


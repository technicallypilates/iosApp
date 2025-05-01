import AVFoundation
import Vision
import UIKit
import SwiftUI
import CoreML

class PoseEstimator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Binding private var poseLabel: String
    @Binding private var poseColor: Color
    @Binding private var startDetection: Bool
    @Binding private var repCount: Int
    @Binding private var logEntries: [PoseLogEntry]
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInteractive)
    var captureSession: AVCaptureSession?
    private var selectedRoutine: Routine?
    private var currentPoseIndex: Int = 0
    private var lastPoseTime: Date?
    private var comboCount: Int = 0
    private var onNewEntry: (PoseLogEntry) -> Void
    private var onComboBroken: () -> Void
    private var poseClassifier: PoseClassifier?
    
    // Properties for accuracy tracking
    private var consecutiveCorrectPoses: Int = 0
    private var hasAchievedHighAccuracy: Bool = false
    
    // Mapping of model output indices to pose names
    private let poseLabels: [Int: String] = [
        0: "FullRollUp"
        // Additional poses will be added here as the model is updated
    ]
    
    // Properties for velocity calculations and smoothing
    private var previousPositions: [VNHumanBodyPoseObservation.JointName: CGPoint]?
    private var previousTimestamp: CMTime?
    private let frameRate: Double = 30.0
    private let velocitySmoothingFactor: Float = 0.3
    private var previousVelocities: [VNHumanBodyPoseObservation.JointName: (x: Float, y: Float)] = [:]
    
    // Key joints to track for motion analysis
    private let trackedJoints: [VNHumanBodyPoseObservation.JointName] = [
        .leftHip,
        .rightHip,
        .leftShoulder,
        .rightShoulder,
        .leftKnee,
        .rightKnee,
        .leftAnkle,
        .rightAnkle
    ]
    
    init(poseLabel: Binding<String>,
         poseColor: Binding<Color>,
         startDetection: Binding<Bool>,
         repCount: Binding<Int>,
         logEntries: Binding<[PoseLogEntry]>,
         onNewEntry: @escaping (PoseLogEntry) -> Void,
         onComboBroken: @escaping () -> Void) {
        _poseLabel = poseLabel
        _poseColor = poseColor
        _startDetection = startDetection
        _repCount = repCount
        _logEntries = logEntries
        self.onNewEntry = onNewEntry
        self.onComboBroken = onComboBroken
        
        // Initialize the Core ML model
        do {
            let config = MLModelConfiguration()
            poseClassifier = try PoseClassifier(configuration: config)
        } catch {
            print("Error initializing PoseClassifier: \(error)")
        }
        
        super.init()
    }
    
    func startSession() {
        let session = AVCaptureSession()
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
        
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        
        session.commitConfiguration()
        captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func updateState(startDetection: Bool, selectedRoutine: Routine, currentPoseIndex: Int) {
        self.startDetection = startDetection
        self.selectedRoutine = selectedRoutine
        self.currentPoseIndex = currentPoseIndex
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard startDetection,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let selectedRoutine = selectedRoutine else { return }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        let poseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                return
            }
            
            self.processPoseObservation(observation, for: selectedRoutine.exercises[self.currentPoseIndex], timestamp: timestamp)
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([poseRequest])
    }
    
    private func processPoseObservation(_ observation: VNHumanBodyPoseObservation, for exercise: Exercise, timestamp: Date) {
        guard let features = extractFeatures(from: observation, timestamp: timestamp),
              let classifier = poseClassifier else {
            DispatchQueue.main.async { [weak self] in
                self?.poseLabel = "Unable to detect pose"
                self?.poseColor = .red
            }
            return
        }
        
        do {
            // Create input for the Core ML model
            let input = try MLMultiArray(shape: [1, 9], dataType: .float32)
            for (index, feature) in features.enumerated() {
                input[index] = NSNumber(value: feature)
            }
            
            // Make prediction
            let prediction = try classifier.prediction(input_1: input)
            
            // Get the output tensor from the prediction
            let outputFeature = prediction.featureValue(for: "Identity")
            guard let probabilities = outputFeature?.multiArrayValue else {
                throw NSError(domain: "PoseEstimator", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get prediction probabilities"])
            }
            
            // For debugging purposes
            print("Number of classes in prediction: \(probabilities.count)")
            
            // Get probability for the predicted pose
            let probability = probabilities[0].floatValue  // Currently only FullRollUp at index 0
            
            // For debugging purposes
            print("Probability for \(poseLabels[0] ?? "unknown"): \(probability)")
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if probability > 0.7 && exercise.name == self.poseLabels[0] {
                    // Calculate XP based on accuracy
                    let xp = XPSystem.calculateXP(
                        accuracy: Double(probability),
                        isFirstTimeHighAccuracy: !self.hasAchievedHighAccuracy && probability >= 0.9,
                        consecutiveCorrectPoses: self.consecutiveCorrectPoses
                    )
                    
                    // Update tracking variables
                    if probability >= 0.9 {
                        self.hasAchievedHighAccuracy = true
                    }
                    self.consecutiveCorrectPoses += 1
                    
                    self.poseLabel = "\(exercise.name) (Accuracy: \(Int(probability * 100))%)"
                    self.poseColor = .green
                    self.repCount += 1
                    
                    let entry = PoseLogEntry(
                        poseId: exercise.id,
                        routineId: self.selectedRoutine?.id ?? UUID(),
                        repsCompleted: self.repCount,
                        accuracy: Double(probability),
                        xpEarned: xp
                    )
                    self.logEntries.append(entry)
                    self.onNewEntry(entry)
                } else {
                    // Reset consecutive correct poses counter
                    self.consecutiveCorrectPoses = 0
                    
                    // For debugging purposes
                    print("Pose mismatch or low confidence:")
                    print("Expected pose: \(exercise.name)")
                    print("Detected pose: \(self.poseLabels[0] ?? "unknown")")
                    print("Confidence: \(probability)")
                    
                    self.poseLabel = "Incorrect Pose (Accuracy: \(Int(probability * 100))%)"
                    self.poseColor = .red
                    self.onComboBroken()
                }
            }
        } catch {
            print("Error making prediction: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.poseLabel = "Error analyzing pose"
                self?.poseColor = .red
            }
        }
    }
    
    private func calculateAngle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        let radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x)
        var angle = abs(radians * 180.0 / .pi)
        if angle > 180.0 {
            angle = 360 - angle
        }
        return angle
    }
    
    private func extractFeatures(from observation: VNHumanBodyPoseObservation, timestamp: Date) -> [Float]? {
        // First, extract all required points
        var currentPositions: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        var velocities: [VNHumanBodyPoseObservation.JointName: (x: Float, y: Float)] = [:]
        
        // Extract current positions for all tracked joints
        for joint in trackedJoints {
            if let point = try? observation.recognizedPoint(joint) {
                currentPositions[joint] = CGPoint(x: point.location.x, y: point.location.y)
            }
        }
        
        // Calculate velocities with smoothing
        if let previousPositions = previousPositions,
           let previousTime = previousTimestamp {
            let timeDiff = CMTimeGetSeconds(CMTimeSubtract(timestamp, previousTime))
            
            if timeDiff > 0 {
                for joint in trackedJoints {
                    if let currentPos = currentPositions[joint],
                       let prevPos = previousPositions[joint] {
                        // Calculate raw velocity
                        let rawVelocityX = Float((currentPos.x - prevPos.x) / timeDiff)
                        let rawVelocityY = Float((currentPos.y - prevPos.y) / timeDiff)
                        
                        // Apply smoothing
                        let prevVelocity = previousVelocities[joint] ?? (0, 0)
                        let smoothedVelocityX = velocitySmoothingFactor * rawVelocityX + 
                                              (1 - velocitySmoothingFactor) * prevVelocity.x
                        let smoothedVelocityY = velocitySmoothingFactor * rawVelocityY + 
                                              (1 - velocitySmoothingFactor) * prevVelocity.y
                        
                        // Normalize velocities
                        let maxVelocity: Float = 100.0
                        velocities[joint] = (
                            min(max(smoothedVelocityX / maxVelocity, -1.0), 1.0),
                            min(max(smoothedVelocityY / maxVelocity, -1.0), 1.0)
                        )
                    }
                }
            }
        }
        
        // Update previous values
        previousPositions = currentPositions
        previousVelocities = velocities
        previousTimestamp = timestamp
        
        // Extract required points for angle calculations
        guard let leftShoulder = currentPositions[.leftShoulder],
              let rightShoulder = currentPositions[.rightShoulder],
              let leftElbow = try? observation.recognizedPoint(.leftElbow),
              let rightElbow = try? observation.recognizedPoint(.rightElbow),
              let leftWrist = try? observation.recognizedPoint(.leftWrist),
              let rightWrist = try? observation.recognizedPoint(.rightWrist),
              let leftHip = currentPositions[.leftHip],
              let rightHip = currentPositions[.rightHip],
              let leftKnee = currentPositions[.leftKnee],
              let rightKnee = currentPositions[.rightKnee],
              let leftAnkle = currentPositions[.leftAnkle],
              let rightAnkle = currentPositions[.rightAnkle] else {
            return nil
        }
        
        // Calculate angles (using the same angle calculation as before)
        let leftHipAngle = calculateAngle(
            a: leftShoulder,
            b: leftHip,
            c: leftKnee
        )
        
        let rightHipAngle = calculateAngle(
            a: rightShoulder,
            b: rightHip,
            c: rightKnee
        )
        
        let leftElbowAngle = calculateAngle(
            a: leftShoulder,
            b: CGPoint(x: leftElbow.location.x, y: leftElbow.location.y),
            c: CGPoint(x: leftWrist.location.x, y: leftWrist.location.y)
        )
        
        let rightElbowAngle = calculateAngle(
            a: rightShoulder,
            b: CGPoint(x: rightElbow.location.x, y: rightElbow.location.y),
            c: CGPoint(x: rightWrist.location.x, y: rightWrist.location.y)
        )
        
        let leftKneeAngle = calculateAngle(
            a: leftHip,
            b: leftKnee,
            c: leftAnkle
        )
        
        let rightKneeAngle = calculateAngle(
            a: rightHip,
            b: rightKnee,
            c: rightAnkle
        )
        
        // Use the average velocity of tracked points
        let avgVelocityX = velocities.values.map { $0.x }.reduce(0, +) / Float(velocities.count)
        let avgVelocityY = velocities.values.map { $0.y }.reduce(0, +) / Float(velocities.count)
        
        return [
            Float(leftHipAngle),
            Float(rightHipAngle),
            Float(leftElbowAngle),
            Float(rightElbowAngle),
            Float(leftKneeAngle),
            Float(rightKneeAngle),
            avgVelocityX,
            avgVelocityY,
            0.0 // Z-axis velocity (still 0 as we don't have depth)
        ]
    }
} 
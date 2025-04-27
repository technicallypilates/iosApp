import AVFoundation
import Vision
import UIKit
import SwiftUI

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
    private var onNewEntry: (PoseLogEntry) -> Void
    private var onComboBroken: () -> Void
    
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
        
        let poseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                return
            }
            
            self.processPoseObservation(observation, for: selectedRoutine.poses[self.currentPoseIndex])
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([poseRequest])
    }
    
    private func processPoseObservation(_ observation: VNHumanBodyPoseObservation, for expectedPose: Pose) {
        // Here you would implement the logic to compare the observed pose with the expected pose
        // This is a placeholder implementation
        let matchConfidence: Float = 0.8 // This should be calculated based on pose matching
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if matchConfidence > 0.7 {
                self.poseLabel = expectedPose.name
                self.poseColor = .green
                self.repCount += 1
                
                let entry = PoseLogEntry(
                    poseId: expectedPose.id,
                    routineId: self.selectedRoutine?.id ?? UUID(),
                    repsCompleted: self.repCount
                )
                self.logEntries.append(entry)
                self.onNewEntry(entry)
            } else {
                self.poseLabel = "Incorrect Pose"
                self.poseColor = .red
                self.onComboBroken()
            }
        }
    }
} 
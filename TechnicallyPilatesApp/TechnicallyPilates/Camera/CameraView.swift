import SwiftUI
import AVFoundation
import Vision

class CameraViewModel: ObservableObject {
    @Published var isCameraAuthorized = false
    @Published var currentPose: String = ""
    @Published var confidence: Double = 0.0
    
    private let session = AVCaptureSession()
    private let poseEstimator = PoseEstimator()
    
    func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            isCameraAuthorized = false
        }
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
        session.startRunning()
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
            if let observations = request.results {
                for observation in observations {
                    poseEstimator.processObservation(observation) { [weak self] pose, confidence in
                        DispatchQueue.main.async {
                            self?.currentPose = pose
                            self?.confidence = confidence
                        }
                    }
                }
            }
        } catch {
            print("Error processing pose: \(error.localizedDescription)")
        }
    }
}

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isCameraAuthorized {
                CameraPreviewView()
                    .overlay(
                        VStack {
                            Text("Current Pose: \(viewModel.currentPose)")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            
                            Text("Confidence: \(Int(viewModel.confidence * 100))%")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    )
            } else {
                VStack {
                    Text("Camera access is required")
                        .font(.headline)
                    Button("Grant Access") {
                        viewModel.checkCameraAuthorization()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .onAppear {
            viewModel.checkCameraAuthorization()
        }
    }
}

#Preview {
    CameraView()
} 
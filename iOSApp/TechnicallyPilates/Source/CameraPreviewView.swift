import SwiftUI
import AVFoundation
import Vision

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

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        let poseEstimator = PoseEstimator(
            poseLabel: $poseLabel,
            poseColor: $poseColor,
            startDetection: $startDetection,
            repCount: $repCount,
            logEntries: $logEntries,
            onNewEntry: onNewEntry,
            onComboBroken: onComboBroken
        )
        
        // Store the pose estimator in the coordinator
        context.coordinator.poseEstimator = poseEstimator
        
        // Set up the preview layer
        view.session = poseEstimator.captureSession
        
        // Start the camera session
        poseEstimator.startSession()
        
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.poseEstimator?.updateState(
            startDetection: startDetection,
            selectedRoutine: selectedRoutine,
            currentPoseIndex: currentPoseIndex
        )
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject {
        var poseEstimator: PoseEstimator?
    }
}

class PreviewView: UIView {
    var session: AVCaptureSession? {
        get { return videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
}



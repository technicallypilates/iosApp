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
}



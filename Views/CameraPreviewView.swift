import SwiftUI
import AVFoundation
import Vision
import Foundation

struct CameraPreviewView: UIViewRepresentable {
    @Binding var poseLabel: String
    @Binding var poseColor: Color
    @Binding var startDetection: Bool
    @Binding var repCount: Int
    @Binding var logEntries: [PoseLogEntry]
    @Binding var poseAccuracy: Double
    @Binding var currentCorrections: [PoseCorrection]

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
            poseAccuracy: $poseAccuracy,
            currentCorrections: $currentCorrections,
            onNewEntry: onNewEntry,
            onComboBroken: onComboBroken,
            poseBaselines: PoseEstimator.loadBaselineAngles()
        )

        context.coordinator.poseEstimator = poseEstimator

        // Start the session FIRST so captureSession is not nil
        poseEstimator.startSession()

        // Then assign it to the view's preview layer
        view.session = poseEstimator.captureSession

        return view
    }


    func updateUIView(_ uiView: PreviewView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.poseEstimator?.updateState(
                startDetection: startDetection,
                selectedRoutine: selectedRoutine,
                currentPoseIndex: currentPoseIndex
            )
        }
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
        // Configure the preview layer
        videoPreviewLayer.videoGravity = .resizeAspectFill

        // Trigger layout updates — not strictly necessary, but harmless
        videoPreviewLayer.setNeedsLayout()
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        print("📐 PreviewView frame: \(self.frame)")
    }
}


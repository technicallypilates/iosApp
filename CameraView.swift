import SwiftUI
import AVFoundation
import Vision
import UIKit

struct CameraView: UIViewRepresentable {
    @Binding var poseLabel: String
    @Binding var poseColor: Color
    @Binding var startDetection: Bool
    var selectedRoutine: Routine  // 👈 NEW

    class CameraCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        let poseEstimator = PoseEstimator()

        init(parent: CameraView) {
            self.parent = parent
        }

        func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {

            guard parent.startDetection else { return } // ⛔️ Ignore frames until detection starts
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            poseEstimator.performPoseDetection(pixelBuffer: pixelBuffer) { observations, predictedLabel in
                guard let first = observations.first else { return }

                let angles = self.poseEstimator.computeAngles(from: first)

                // ✅ Print angles (optional debugging)
                if let leftHip = angles["leftHipAngle"] {
                    print("🦵 Left Hip Angle: \(Int(leftHip))°")
                }
                if let rightHip = angles["rightHipAngle"] {
                    print("🦵 Right Hip Angle: \(Int(rightHip))°")
                }
                if let leftElbow = angles["leftElbowAngle"] {
                    print("💪 Left Elbow Angle: \(Int(leftElbow))°")
                }
                if let rightElbow = angles["rightElbowAngle"] {
                    print("💪 Right Elbow Angle: \(Int(rightElbow))°")
                }

                // ✅ Log selected routine (optional)
                print("📋 Routine in use: \(self.parent.selectedRoutine.rawValue)")

                // ✅ Update label and color in UI thread
                DispatchQueue.main.async {
                    if let label = predictedLabel {
                        self.parent.poseLabel = label

                        if label.lowercased().contains("correct") {
                            self.parent.poseColor = .green
                        } else {
                            self.parent.poseColor = .red
                            self.triggerVibration()
                        }
                    } else {
                        self.parent.poseLabel = "Analyzing..."
                        self.parent.poseColor = .gray
                    }
                }
            }
        }

        /// 📳 Haptic vibration for incorrect pose
        private func triggerVibration() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    func makeCoordinator() -> CameraCoordinator {
        return CameraCoordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return view
        }

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

    func updateUIView(_ uiView: UIView, context: Context) {
        // You could use this to update the view dynamically later if needed
    }
}


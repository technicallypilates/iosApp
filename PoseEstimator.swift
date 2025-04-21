import Vision
import CoreML
import AVFoundation
import CoreGraphics

class PoseEstimator {
    private let request = VNDetectHumanBodyPoseRequest()
    private var classifier: PoseClassifier?

    // You can put your real pose labels here!
    private let poseLabels = ["PoseA", "PoseB"] // TODO: 🔥 Replace with actual labels if known

    init() {
        self.classifier = try? PoseClassifier(configuration: MLModelConfiguration())
    }

    /// Detects body pose and returns both the VN observations and predicted label
    func performPoseDetection(pixelBuffer: CVPixelBuffer,
                               completion: @escaping ([VNHumanBodyPoseObservation], String?) -> Void) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([self.request])
                guard let results = self.request.results,
                      let first = results.first else {
                    completion([], nil)
                    return
                }

                let angles = self.computeAngles(from: first)

                // Extract all 6 angles expected by the model
                guard let leftHip = angles["leftHipAngle"],
                      let rightHip = angles["rightHipAngle"],
                      let leftElbow = angles["leftElbowAngle"],
                      let rightElbow = angles["rightElbowAngle"],
                      let leftKnee = angles["leftKneeAngle"],
                      let rightKnee = angles["rightKneeAngle"] else {
                    completion(results, nil)
                    return
                }

                // Create and populate MLMultiArray with 1x6 shape
                let inputArray = try MLMultiArray(shape: [1, 6], dataType: .float32)
                inputArray[[0, 0] as [NSNumber]] = NSNumber(value: Float(leftHip))
                inputArray[[0, 1] as [NSNumber]] = NSNumber(value: Float(rightHip))
                inputArray[[0, 2] as [NSNumber]] = NSNumber(value: Float(leftElbow))
                inputArray[[0, 3] as [NSNumber]] = NSNumber(value: Float(rightElbow))
                inputArray[[0, 4] as [NSNumber]] = NSNumber(value: Float(leftKnee))
                inputArray[[0, 5] as [NSNumber]] = NSNumber(value: Float(rightKnee))

                guard let classifier = self.classifier else {
                    print("❌ Classifier not available.")
                    completion(results, nil)
                    return
                }

                let modelInput = PoseClassifierInput(pose_input: inputArray)
                let prediction = try classifier.prediction(input: modelInput)

                // Get prediction output (Identity: 1xN scores)
                let outputArray = prediction.IdentityShapedArray
                let bestIndex = outputArray.scalars.enumerated().max(by: { $0.element < $1.element })?.offset

                // Dynamically map best index to pose label
                let label = (bestIndex != nil && bestIndex! < self.poseLabels.count) ? self.poseLabels[bestIndex!] : nil

                completion(results, label)

            } catch {
                print("⚠️ Vision or ML error: \(error.localizedDescription)")
                completion([], nil)
            }
        }
    }

    /// Extracts angles between joints for use in classification
    func computeAngles(from observation: VNHumanBodyPoseObservation) -> [String: CGFloat] {
        do {
            let points = try observation.recognizedPoints(.all)

            func convert(_ point: VNRecognizedPoint?) -> CGPoint? {
                guard let p = point, p.confidence > 0.5 else { return nil }
                return CGPoint(x: p.location.x, y: 1 - p.location.y)
            }

            let leftShoulder = convert(points[.leftShoulder])
            let leftHip = convert(points[.leftHip])
            let leftKnee = convert(points[.leftKnee])
            let leftAnkle = convert(points[.leftAnkle])
            let rightShoulder = convert(points[.rightShoulder])
            let rightHip = convert(points[.rightHip])
            let rightKnee = convert(points[.rightKnee])
            let rightAnkle = convert(points[.rightAnkle])
            let leftElbow = convert(points[.leftElbow])
            let leftWrist = convert(points[.leftWrist])
            let rightElbow = convert(points[.rightElbow])
            let rightWrist = convert(points[.rightWrist])

            var angles: [String: CGFloat] = [:]

            // Hip angles
            if let a = leftShoulder, let b = leftHip, let c = leftKnee {
                angles["leftHipAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }
            if let a = rightShoulder, let b = rightHip, let c = rightKnee {
                angles["rightHipAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }

            // Elbow angles
            if let a = leftShoulder, let b = leftElbow, let c = leftWrist {
                angles["leftElbowAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }
            if let a = rightShoulder, let b = rightElbow, let c = rightWrist {
                angles["rightElbowAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }

            // Knee angles
            if let a = leftHip, let b = leftKnee, let c = leftAnkle {
                angles["leftKneeAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }
            if let a = rightHip, let b = rightKnee, let c = rightAnkle {
                angles["rightKneeAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }

            return angles

        } catch {
            print("⚠️ Angle extraction error: \(error)")
            return [:]
        }
    }

    /// Calculates angle at jointB formed by A-B-C
    private func angleBetween(jointA: CGPoint, jointB: CGPoint, jointC: CGPoint) -> CGFloat {
        let vector1 = CGVector(dx: jointA.x - jointB.x, dy: jointA.y - jointB.y)
        let vector2 = CGVector(dx: jointC.x - jointB.x, dy: jointC.y - jointB.y)

        let dot = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let mag1 = sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy)
        let mag2 = sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy)

        guard mag1 > 0, mag2 > 0 else { return 0 }

        let cosTheta = dot / (mag1 * mag2)
        let clamped = max(min(cosTheta, 1), -1)
        return acos(clamped) * 180 / .pi
    }
}

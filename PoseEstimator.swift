import Vision
import CoreML
import AVFoundation
import CoreGraphics

class PoseEstimator {
    private let request = VNDetectHumanBodyPoseRequest()
    private var classifier: PoseClassifier?

    init() {
        self.classifier = try? PoseClassifier(configuration: MLModelConfiguration())
    }

    func performPoseDetection(pixelBuffer: CVPixelBuffer, completion: @escaping ([VNHumanBodyPoseObservation], String?) -> Void) {
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

                // Extract angles in fixed order expected by model
                guard let leftHip = angles["leftHipAngle"],
                      let rightHip = angles["rightHipAngle"],
                      let leftElbow = angles["leftElbowAngle"],
                      let rightElbow = angles["rightElbowAngle"] else {
                    completion(results, nil)
                    return
                }

                guard let classifier = self.classifier else {
                    print("❌ Classifier not available.")
                    completion(results, nil)
                    return
                }

                // 👇 Build MLMultiArray to match model input
                let inputArray = try MLMultiArray(shape: [4], dataType: .double)
                inputArray[0] = NSNumber(value: Double(leftHip))
                inputArray[1] = NSNumber(value: Double(rightHip))
                inputArray[2] = NSNumber(value: Double(leftElbow))
                inputArray[3] = NSNumber(value: Double(rightElbow))

                let modelInput = PoseClassifierInput(input_1: inputArray)
                let prediction = try classifier.prediction(input: modelInput)
                let label = prediction.classLabel

                completion(results, label)

            } catch {
                print("Vision or ML error: \(error)")
                completion([], nil)
            }
        }
    }

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

            let rightShoulder = convert(points[.rightShoulder])
            let rightHip = convert(points[.rightHip])
            let rightKnee = convert(points[.rightKnee])

            let leftElbow = convert(points[.leftElbow])
            let leftWrist = convert(points[.leftWrist])

            let rightElbow = convert(points[.rightElbow])
            let rightWrist = convert(points[.rightWrist])

            var angles: [String: CGFloat] = [:]

            if let a = leftShoulder, let b = leftHip, let c = leftKnee {
                angles["leftHipAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }

            if let a = rightShoulder, let b = rightHip, let c = rightKnee {
                angles["rightHipAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }

            if let a = leftShoulder, let b = leftElbow, let c = leftWrist {
                angles["leftElbowAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }

            if let a = rightShoulder, let b = rightElbow, let c = rightWrist {
                angles["rightElbowAngle"] = angleBetween(jointA: a, jointB: b, jointC: c)
            }

            return angles

        } catch {
            print("⚠️ Angle extraction error:", error)
            return [:]
        }
    }

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


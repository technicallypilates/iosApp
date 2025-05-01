


import cv2
import mediapipe as mp
import numpy as np
from utils import calculate_angle

mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose

class PoseEstimator:
    def __init__(self, confidence_threshold=0.5):
        self.pose = mp_pose.Pose(min_detection_confidence=confidence_threshold, min_tracking_confidence=confidence_threshold)
        self.confidence_threshold = confidence_threshold

    def detect_pose(self, frame):
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.pose.process(image)
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

        confidence_score = self.calculate_confidence(results)
        landmarks = results.pose_landmarks if confidence_score >= self.confidence_threshold else None

        if landmarks:
            self.draw_landmarks(image, landmarks)
        else:
            cv2.putText(image, "Low confidence! Try adjusting position.", (10, 50),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)

        return image, landmarks, confidence_score

    def calculate_confidence(self, results):
        if not results.pose_landmarks:
            return 0.0

        confidences = [lm.visibility for lm in results.pose_landmarks.landmark]
        return sum(confidences) / len(confidences)

    def draw_landmarks(self, image, landmarks):
        mp_drawing.draw_landmarks(image, landmarks, mp_pose.POSE_CONNECTIONS,
                                  mp_drawing.DrawingSpec(color=(0, 255, 0), thickness=2, circle_radius=3),
                                  mp_drawing.DrawingSpec(color=(0, 0, 255), thickness=2, circle_radius=3))

        height, width, _ = image.shape
        landmark_points = [(int(lm.x * width), int(lm.y * height)) for lm in landmarks.landmark]

        self.draw_angles(image, landmark_points)

    def draw_angles(self, image, landmarks):
        def get_point(index):
            return landmarks[index] if len(landmarks) > index else None

        keypoints = [
            (11, 23, 25), (12, 24, 26),  # Hips
            (13, 15, 11), (14, 16, 12)   # Elbows
        ]

        for p1, p2, p3 in keypoints:
            pt1, pt2, pt3 = get_point(p1), get_point(p2), get_point(p3)
            if pt1 and pt2 and pt3:
                angle = calculate_angle(pt1, pt2, pt3)
                self.draw_text(image, pt2, angle)

    def draw_text(self, image, position, angle):
        x, y = position
        cv2.putText(image, f"{int(angle)}°", (x + 10, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 255), 2)

if __name__ == "__main__":
    cap = cv2.VideoCapture(0)
    pose_estimator = PoseEstimator(confidence_threshold=0.5)

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        frame, _, confidence = pose_estimator.detect_pose(frame)
        cv2.putText(frame, f"Confidence: {confidence:.2f}", (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.imshow('Pose Estimation', frame)

        if cv2.waitKey(10) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()




import csv
import os
import numpy as np
from utils import calculate_angle
from ml_model import PoseCoachML

class PoseFeedback:
    def __init__(self, confidence_threshold=0.5, log_file="pose_data.csv"):
        self.confidence_threshold = confidence_threshold
        self.log_file = log_file
        self.model = PoseCoachML()  # `load_model()` is already called in PoseCoachML's constructor

        # Ensure the CSV file has headers if it doesn't exist
        if not os.path.exists(self.log_file):
            with open(self.log_file, mode='w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(["left_hip_angle", "right_hip_angle", "left_shoulder_angle", "right_shoulder_angle", "left_knee_angle", "right_knee_angle", "confidence", "feedback", "label"])

    def evaluate_pose(self, landmarks, confidence):
        """Evaluate Pilates pose using key joint angles and return feedback with confidence."""
        if confidence is not None and confidence < self.confidence_threshold:
            return "Pose not detected clearly. Try again.", confidence, None

        if isinstance(landmarks, list):  # Handling test data (list format)
            landmark_list = landmarks
        else:  # Handling real MediaPipe data
            landmark_list = landmarks.landmark

        def get_landmark(index):
            """Safely retrieve a landmark, return None if unavailable."""
            if landmark_list and len(landmark_list) > index and landmark_list[index] is not None:
                return [landmark_list[index].x, landmark_list[index].y]
            return None

        # Define key points
        left_shoulder = get_landmark(11)
        left_hip = get_landmark(23)
        left_knee = get_landmark(25)
        right_shoulder = get_landmark(12)
        right_hip = get_landmark(24)
        right_knee = get_landmark(26)

        feedback = []

        # Compute angles
        angles = [
            calculate_angle(left_shoulder, left_hip, left_knee) if left_shoulder and left_hip and left_knee else None,
            calculate_angle(right_shoulder, right_hip, right_knee) if right_shoulder and right_hip and right_knee else None,
            calculate_angle(left_hip, left_shoulder, right_shoulder) if left_hip and left_shoulder and right_shoulder else None,
            calculate_angle(left_shoulder, right_shoulder, right_hip) if left_shoulder and right_shoulder and right_hip else None,
            calculate_angle(left_hip, left_knee, right_knee) if left_hip and left_knee and right_knee else None,
            calculate_angle(right_hip, right_knee, left_knee) if right_hip and right_knee and left_knee else None
        ]

        if None in angles:
            print("Invalid angles detected:", angles)
            return "Pose not fully detected.", confidence, None

        # Ensure angles is a NumPy array with shape (1, 6)
        angles = np.array(angles, dtype=np.float32).reshape(1, -1)
        print("Shape of angles:", angles.shape)
        print("Contents of angles:", angles)

        prediction = self.model.predict_pose(angles)
        label = "Correct" if prediction == 1 else "Incorrect"

        # Generate feedback based on angles
        if 85 <= angles[0, 0] <= 95 and 85 <= angles[0, 1] <= 95:
            feedback.append("Good posture on both sides!")
        else:
            if angles[0, 0] < 85:
                feedback.append("Straighten up your back on the left side!")
            elif angles[0, 0] > 95:
                feedback.append("Lower your hips slightly on the left side!")
            if angles[0, 1] < 85:
                feedback.append("Straighten up your back on the right side!")
            elif angles[0, 1] > 95:
                feedback.append("Lower your hips slightly on the right side!")

        # Log data to CSV file
        with open(self.log_file, mode='a', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(list(angles.flatten()) + [confidence, " ".join(feedback), label])

        return " ".join(feedback) if feedback else "No pose detected", confidence, angles

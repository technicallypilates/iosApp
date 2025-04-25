

import cv2
import numpy as np
import csv
from camera import Camera
from pose_estimator import PoseEstimator
from feedback import PoseFeedback
from ml_model import PoseCoachML

def draw_feedback_overlay(frame, feedback_text, confidence_score):
    """Draw feedback text and confidence score on the frame."""
    height, width, _ = frame.shape
    overlay = frame.copy()

    # Set text color based on confidence score
    if confidence_score is None:
        color = (0, 0, 255)  # Red for no confidence score
    elif confidence_score > 90:
        color = (0, 255, 0)  # Green for high confidence
    elif confidence_score > 70:
        color = (0, 255, 255)  # Yellow for medium confidence
    else:
        color = (0, 165, 255)  # Orange for low confidence

    # Draw feedback text
    cv2.putText(overlay, feedback_text, (30, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2, cv2.LINE_AA)

    # Draw confidence score if available
    if confidence_score is not None:
        confidence_text = f"Confidence: {confidence_score:.1f}"
        cv2.putText(overlay, confidence_text, (30, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2, cv2.LINE_AA)

    return overlay

def log_pose_data(angles, prediction):
    """Log pose angles and predictions to a CSV file."""
    if isinstance(angles, np.ndarray):
        angles = angles.tolist()  # Convert NumPy array to a list

    with open("pose_data_clean.csv", mode="a", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(angles + [str(prediction)])  # Ensure prediction is a string


def main():
    camera = Camera()
    pose_estimator = PoseEstimator()
    feedback_system = PoseFeedback()
    pose_coach = PoseCoachML()

    while True:
        frame = camera.get_frame()
        if frame is None:
            break

        # Detect Pose
        frame, landmarks, confidence_score = pose_estimator.detect_pose(frame)

        # Ensure landmarks are valid before processing
        feedback_text = "No pose detected"
        prediction = "Unknown"

        if landmarks is not None:
            feedback_text, confidence, angles = feedback_system.evaluate_pose(landmarks, confidence_score)
            angles = np.array(angles).flatten()  # Ensure it's a 1D array
            print(f"Angles before prediction: {angles}, Type: {type(angles)}, Shape: {angles.shape}")

            if angles.shape[0] == 6:
                prediction = pose_coach.predict_pose(angles)
            else:
                raise ValueError(f"Expected 6 angles, but got {angles}")

            log_pose_data(angles, prediction)

        # Overlay feedback on frame
        frame = draw_feedback_overlay(frame, f"{feedback_text} ({prediction})", confidence_score)

        # Show the frame
        cv2.imshow("Pilates Pose Tracker", frame)

        # Press 'q' to exit
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    camera.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()

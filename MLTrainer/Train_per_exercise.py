import cv2
import mediapipe as mp
import pandas as pd
import numpy as np
import os

# Setup
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(static_image_mode=False)
data = []

# Path to your videos
videos_folder = '/Users/patrickorourke/Desktop/PoseVideos/FullRollUp'

# Loop over all videos
for video_file in os.listdir(videos_folder):
    if video_file.endswith('.mov'):
        cap = cv2.VideoCapture(os.path.join(videos_folder, video_file))

        prev_landmarks = None

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            # Convert frame to RGB for MediaPipe
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            result = pose.process(frame_rgb)

            if result.pose_landmarks:
                landmarks = result.pose_landmarks.landmark
                # Extract keypoints you need
                left_hip = [landmarks[mp_pose.PoseLandmark.LEFT_HIP.value].x,
                            landmarks[mp_pose.PoseLandmark.LEFT_HIP.value].y]
                right_hip = [landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value].x,
                             landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value].y]
                left_elbow = [landmarks[mp_pose.PoseLandmark.LEFT_ELBOW.value].x,
                              landmarks[mp_pose.PoseLandmark.LEFT_ELBOW.value].y]
                right_elbow = [landmarks[mp_pose.PoseLandmark.RIGHT_ELBOW.value].x,
                               landmarks[mp_pose.PoseLandmark.RIGHT_ELBOW.value].y]
                left_knee = [landmarks[mp_pose.PoseLandmark.LEFT_KNEE.value].x,
                             landmarks[mp_pose.PoseLandmark.LEFT_KNEE.value].y]
                right_knee = [landmarks[mp_pose.PoseLandmark.RIGHT_KNEE.value].x,
                              landmarks[mp_pose.PoseLandmark.RIGHT_KNEE.value].y]
                left_shoulder = [landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value].x,
                                 landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value].y]
                right_shoulder = [landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value].x,
                                  landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value].y]
                left_wrist = [landmarks[mp_pose.PoseLandmark.LEFT_WRIST.value].x,
                              landmarks[mp_pose.PoseLandmark.LEFT_WRIST.value].y]
                right_wrist = [landmarks[mp_pose.PoseLandmark.RIGHT_WRIST.value].x,
                               landmarks[mp_pose.PoseLandmark.RIGHT_WRIST.value].y]
                left_ankle = [landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value].x,
                              landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value].y]
                right_ankle = [landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value].x,
                               landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value].y]


                # Calculate angles
                def calculate_angle(a, b, c):
                    a = np.array(a)
                    b = np.array(b)
                    c = np.array(c)
                    radians = np.arctan2(c[1] - b[1], c[0] - b[0]) - np.arctan2(a[1] - b[1], a[0] - b[0])
                    angle = np.abs(radians * 180.0 / np.pi)
                    if angle > 180.0:
                        angle = 360 - angle
                    return angle


                left_hip_angle = calculate_angle(left_shoulder, left_hip, left_knee)
                right_hip_angle = calculate_angle(right_shoulder, right_hip, right_knee)
                left_elbow_angle = calculate_angle(left_shoulder, left_elbow, left_wrist)
                right_elbow_angle = calculate_angle(right_shoulder, right_elbow, right_wrist)
                left_knee_angle = calculate_angle(left_hip, left_knee, left_ankle)
                right_knee_angle = calculate_angle(right_hip, right_knee, right_ankle)

                # Calculate velocities (optional)
                if prev_landmarks is not None:
                    velocity_x = left_hip[0] - prev_landmarks[0]
                    velocity_y = left_hip[1] - prev_landmarks[1]
                    velocity_z = 0  # 2D for now
                else:
                    velocity_x = velocity_y = velocity_z = 0

                prev_landmarks = left_hip  # Update previous landmark

                # Save feature vector
                feature = [left_hip_angle, right_hip_angle, left_elbow_angle,
                           right_elbow_angle, left_knee_angle, right_knee_angle,
                           velocity_x, velocity_y, velocity_z]
                data.append(feature)

        cap.release()

# Save dataset
df = pd.DataFrame(data, columns=[
    'leftHipAngle', 'rightHipAngle',
    'leftElbowAngle', 'rightElbowAngle',
    'leftKneeAngle', 'rightKneeAngle',
    'velocityX', 'velocityY', 'velocityZ'
])
df['label'] = 'FullRollUp'  # All these samples are 'Full Roll Up'
df.to_csv('pose_training_data.csv', index=False)

print("Data extraction complete!")

# ml_model.py

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

# ✅ Build Pose Model with named input "pose_input"
def build_pose_model(input_shape=(6,), num_classes=2):
    model = keras.Sequential([
        layers.Input(shape=input_shape, name="pose_input"),  # <-- Input layer explicitly named
        layers.Dense(64, activation='relu'),
        layers.Dense(128, activation='relu'),
        layers.Dense(64, activation='relu'),
        layers.Dense(num_classes, activation='softmax')
    ])

    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )

    return model

# ✅ Inference class for live predictions
class PoseCoachML:
    def __init__(self, model_path="pose_model.h5"):
        self.model = keras.models.load_model(model_path)

    def predict_pose(self, angles):
        """Predict whether the given angles represent a correct pose."""
        if isinstance(angles, list):
            angles = np.array(angles)

        input_data = angles.reshape(1, -1)
        predictions = self.model.predict(input_data, verbose=0)
        predicted_class = np.argmax(predictions, axis=1)[0]

        label_map = {0: "Incorrect", 1: "Correct"}
        return label_map.get(predicted_class, "Unknown")

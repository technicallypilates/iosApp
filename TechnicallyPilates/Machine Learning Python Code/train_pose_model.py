# train_pose_model.py

import numpy as np
import pandas as pd
import tensorflow as tf
from ml_model import build_pose_model

# 📈 Simple Pose Data Augmentation function
def augment_pose_data(X, y, num_augmentations=3, noise_factor=0.05):
    """
    Generate augmented pose data by adding small random noise.

    Args:
        X: Original input data (angles).
        y: Original labels.
        num_augmentations: How many new versions to generate per sample.
        noise_factor: Max noise % to apply (0.05 = ±5%).

    Returns:
        Augmented X, y including originals.
    """
    augmented_X = []
    augmented_y = []

    for i in range(len(X)):
        original = X[i]
        label = y[i]

        for _ in range(num_augmentations):
            noise = np.random.uniform(
                low=1 - noise_factor,
                high=1 + noise_factor,
                size=original.shape
            )
            new_sample = original * noise
            new_sample = np.clip(new_sample, 0, 180)  # Keep angles realistic
            augmented_X.append(new_sample)
            augmented_y.append(label)

    # Stack originals and augmented samples
    X_augmented = np.vstack([X, np.array(augmented_X)])
    y_augmented = np.hstack([y, np.array(augmented_y)])

    return X_augmented, y_augmented

# ✅ Load the clean pose data
data = pd.read_csv("pose_data_clean.csv")

# 🎯 Prepare features (angles) and labels (correct/incorrect)
X_train = data[[
    "left_hip_angle", "right_hip_angle",
    "left_elbow_angle", "right_elbow_angle",
    "left_knee_angle", "right_knee_angle"
]].values

y_train = data["label"].map({"Incorrect": 0, "Correct": 1}).values

# 📊 Check class balance
print("Class distribution (0=Incorrect, 1=Correct) BEFORE augmentation:")
print(pd.Series(y_train).value_counts())

# 📈 Augment the data
X_train, y_train = augment_pose_data(X_train, y_train, num_augmentations=3)
print(f"New training size AFTER augmentation: {X_train.shape[0]} samples")

# ✅ Build the model
model = build_pose_model(input_shape=(6,), num_classes=2)

# ⏳ Setup EarlyStopping callback
early_stopping = tf.keras.callbacks.EarlyStopping(
    monitor='val_loss',
    patience=5,
    restore_best_weights=True
)

# 🧠 Train the model
model.fit(
    X_train, y_train,
    epochs=50,
    batch_size=16,
    validation_split=0.2,
    callbacks=[early_stopping],
    verbose=1
)

# 💾 Save the trained model
model.save("pose_model.h5")
print("✅ Model trained and saved as pose_model.h5")

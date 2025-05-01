# Train_pose_model.py

import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# ✅ Step 1: Load the pose training data
data = pd.read_csv("pose_training_data.csv")

# ✅ Step 2: Split features and labels
X = data[['leftHipAngle', 'rightHipAngle', 'leftElbowAngle', 'rightElbowAngle',
          'leftKneeAngle', 'rightKneeAngle', 'velocityX', 'velocityY', 'velocityZ']].values
y = data['label'].values

# ✅ Step 3: Encode the pose labels to integers
label_encoder = LabelEncoder()
y_encoded = label_encoder.fit_transform(y)

# Save the label mapping for later (useful for decoding predictions)
np.save('label_classes.npy', label_encoder.classes_)

# ✅ Step 4: Split into training and test sets
X_train, X_test, y_train, y_test = train_test_split(X, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded)

# ✅ Step 5: Build the model
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(9,)),  # 9 features now
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dense(len(np.unique(y_encoded)), activation='softmax')  # output layer = number of poses
])

# ✅ Step 6: Compile the model
model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

# ✅ Step 7: Train the model
history = model.fit(X_train, y_train,
                    epochs=50,
                    batch_size=32,
                    validation_data=(X_test, y_test))

# ✅ Step 8: Save the trained model
model.save("pose_model.h5")

print("✅ Model trained and saved as pose_model.h5!")

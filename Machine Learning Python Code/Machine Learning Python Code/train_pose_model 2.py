import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models

# ✅ Define a simple MLP model (6 input features → 2-class output)
model = tf.keras.Sequential([
    layers.Input(shape=(6,)),  # input shape (e.g. angles/distances)
    layers.Dense(16, activation='relu'),
    layers.Dense(8, activation='relu'),
    layers.Dense(2, activation='softmax')  # 2 classes: Correct / Incorrect
])

model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

# 🧪 Dummy data (Replace with actual features if you have)
X_train = np.random.rand(100, 6)  # 100 samples, 6 features each
y_train = np.random.randint(0, 2, size=(100,))  # 0 = incorrect, 1 = correct

# 🧠 Train it
model.fit(X_train, y_train, epochs=10, batch_size=8, verbose=1)

# 💾 Save the model in CoreML-compatible format
model.save("pose_model.h5")
print("✅ Model saved as pose_model.h5")

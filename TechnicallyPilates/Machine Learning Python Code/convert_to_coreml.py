# convert_to_coreml.py

import coremltools as ct
import tensorflow as tf
import numpy as np  # <--- THIS IS REQUIRED

# ✅ Load your trained model
model = tf.keras.models.load_model("pose_model.h5")

# ✅ Convert the model to Core ML
coreml_model = ct.convert(
    model,
    source="tensorflow",
    inputs=[ct.TensorType(shape=(1, 6), dtype=np.float32, name="pose_input")],  # <-- NOTE: np.float32
    convert_to="mlprogram",
    minimum_deployment_target=ct.target.iOS15
)

# ✅ Save the model
coreml_model.save("PoseClassifier.mlpackage")
print("✅ Core ML model saved successfully!")

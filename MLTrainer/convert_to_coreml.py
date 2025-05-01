# convert_to_coreml.py

import coremltools as ct
import tensorflow as tf
import numpy as np  # <--- THIS IS REQUIRED

# ✅ Load your trained model
model = tf.keras.models.load_model("pose_model.h5")

# ✅ Print model input names to double-check
print("Model input names:", [input.name for input in model.inputs])

# ✅ Convert the model to Core ML
# NOTICE: Name must match exactly what you printed ("input_1")
coreml_model = ct.convert(
    model,
    source="tensorflow",
    inputs=[ct.TensorType(shape=(1, 9), dtype=np.float32, name="input_1")],  # <-- NOW correct
    convert_to="mlprogram",
    minimum_deployment_target=ct.target.iOS15
)

# ✅ Save the model
coreml_model.save("PoseClassifier.mlpackage")
print("✅ Core ML model saved successfully!")

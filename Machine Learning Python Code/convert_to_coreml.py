# convert_to_coreml.py

import coremltools as ct
import numpy as np

# Load the existing model
model_path = "pose_model.keras"
print(f"Loading model from {model_path}")

# Convert the model to Core ML
coreml_model = ct.convert(
    model_path,
    source="keras",
    inputs=[ct.TensorType(shape=(1, 9), dtype=np.float32, name="input_1")],
    convert_to="mlprogram",
    minimum_deployment_target=ct.target.iOS15
)

# Save the model
output_path = "PoseClassifier.mlpackage"
coreml_model.save(output_path)
print(f"✅ Core ML model saved successfully to {output_path}!")

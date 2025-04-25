import coremltools as ct
import tensorflow as tf

# Load the trained .h5 model
model = tf.keras.models.load_model("pose_model.h5")

# Convert the Keras model to Core ML format
coreml_model = ct.convert(
    model,
    source="tensorflow",
    inputs=[ct.TensorType(shape=(1, 6))],
    convert_to="mlprogram",  # 👈 ensure it's explicitly an ML Program
    minimum_deployment_target=ct.target.iOS15  # 👈 match device requirements
)

# Save as .mlpackage (required for ML Program models)
coreml_model.save("PoseClassifier.mlpackage")  # ✅ <- KEY FIX

print("✅ Core ML model saved as PoseClassifier.mlpackage")

import numpy as np

# Load the label classes with allow_pickle=True
labels = np.load('label_classes.npy', allow_pickle=True)

# Print the labels with their indices
print("Class labels with indices:")
for i, label in enumerate(labels):
    print(f"{i}: {label}") 
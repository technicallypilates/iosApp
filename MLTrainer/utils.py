


import numpy as np

def calculate_angle(a, b, c):
    """
    Calculate the angle between three points (a, b, c).
    :param a: [x, y] of first point
    :param b: [x, y] of second point (vertex)
    :param c: [x, y] of third point
    :return: Angle in degrees
    """
    a = np.array(a)  # First point
    b = np.array(b)  # Midpoint (vertex)
    c = np.array(c)  # Last point

    # Compute vectors
    ba = a - b
    bc = c - b

    # Compute cosine similarity
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    angle = np.degrees(np.arccos(np.clip(cosine_angle, -1.0, 1.0)))

    return angle

# ✅ Add this test block
if __name__ == "__main__":
    # Test with a right-angle triangle (90 degrees)
    a = [1, 2]
    b = [1, 1]  # Vertex (hip)
    c = [2, 1]

    angle = calculate_angle(a, b, c)
    print(f"Calculated Angle: {angle:.2f}°")  # Expected: 90.0°

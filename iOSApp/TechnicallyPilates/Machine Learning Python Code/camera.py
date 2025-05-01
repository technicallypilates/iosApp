


import cv2

class Camera:
    def __init__(self, source=0):
        """Initialize the camera"""
        self.cap = cv2.VideoCapture(source)

    def is_opened(self):
        """Check if camera is open"""
        return self.cap.isOpened()

    def get_frame(self):
        """Capture a frame from the camera"""
        ret, frame = self.cap.read()
        return frame if ret else None

    def show_frame(self, frame):
        """Display the frame"""
        cv2.imshow("Camera Feed", frame)

    def should_exit(self):
        """Check if user pressed 'q' to exit"""
        return cv2.waitKey(1) & 0xFF == ord('q')

    def release(self):
        """Release the camera and close windows"""
        self.cap.release()
        cv2.destroyAllWindows()

# Test the camera
if __name__ == "__main__":
    cam = Camera()
    while cam.is_opened():
        frame = cam.get_frame()
        if frame is None:
            break
        cam.show_frame(frame)
        if cam.should_exit():
            break
    cam.release()

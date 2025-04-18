TechnicallyPilates 🧘‍♀️📱
A smart iOS Pilates app that uses real-time camera pose detection, repetition counting, streaks, XP leveling, and fun rewards to keep users engaged and progressing! Built entirely in SwiftUI, Vision, and CoreML.

✨ Features
Real-Time Pose Detection (using CoreML + Vision)

Live Pose Feedback (Color-coded labels, accessibility-friendly)

Animated Countdown (beep... beep... beep... GO! 🔔)

Repetition Counting (Detect and count completed reps automatically)

Streak Tracking (🔥 Daily login streak bonuses)

XP & Level System (Gain XP and level up with workouts)

Achievements (Unlock badges for streaks, levels, routines)

Routine Unlocking (New categories unlock as you progress)

Combo Bonus Mode (Perfect streak = bonus XP, fire animations! 🚀🔥)

Cinematic Transitions (Zoom, tilt, glow, sparkle effects)

Success Sound Effects (Chime after successful reps, countdown beeps)

Progress Chart View (Track your improvement over time 📈)

📲 How It Works
Choose a Focus Area:
Select a Routine (Standing, Core, Stretching, etc.) from a simple picker.

Start Detection:
A smooth animated countdown plays (3..2..1..GO!), with sound.

Workout Time:

Pose label and rep count are big, bold, and color coded.

CameraView glows subtly during active detection.

Combo bonuses trigger fire animations and zoom effects!

Celebrate Wins:

After every 10 reps, medals pop up! 🏅

Flash effects when reps complete! 📸

Achievement unlocks for reaching milestones.

Reset / Repeat:
New day, new streak — rack up XP and climb the leaderboards!

🛠 Tech Stack
SwiftUI

CoreML (PoseClassifier model)

Vision (Real-time pose keypoints detection)

AVFoundation (Camera input)

Local Storage (UserDefaults, Codable)

🧪 Daily Regression Test Checklist

Test    Result (✅/❌)
App launches successfully    
Routine picker shows and fades on Start Detection    
Countdown beeps and countdown text animate correctly    
Pose detection starts only after countdown    
Pose label updates with correct pose    
Rep counter increases on holding correct pose    
XP increases per rep    
Level updates based on XP    
Streak counter updates if active across days    
Medal popup shows after 10 reps    
Achievement popup shows when unlocked    
Flash effect plays on rep success    
Combo streak fire effect triggers correctly    
Reset button resets everything properly

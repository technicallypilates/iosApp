# 📋 TechnicallyPilates - Daily Regression Test Checklist

## General UI
- [ ] App launches without crashing
- [ ] "Choose Your Focus" label appears above the routine picker
- [ ] Routine picker is visible and working before Start Detection
- [ ] CameraView visible with "Pose: Waiting..." and "Reps: 0" labels
- [ ] Padding and background styling are applied correctly to picker and labels

---

## Countdown & Start
- [ ] Tapping "Start Detection" triggers animated countdown (beep... beep... beep... GO! 🔔)
- [ ] Countdown includes sound effects at each step
- [ ] CameraView slightly zooms in after countdown ends
- [ ] Routine picker and label fade + slide out smoothly
- [ ] "Camera Starting..." spinner shows during transition

---

## Detection Phase
- [ ] Camera detection starts after countdown
- [ ] CameraView has subtle glowing border during active detection
- [ ] Pose label background color animates (green/red/gray) correctly
- [ ] Rep count updates properly after correct pose detection
- [ ] Flash/white blink appears briefly after successful rep

---

## Streaks & Combos
- [ ] Correct consecutive reps trigger Combo Streak Bonus animation (fire trail, zooming)
- [ ] Combo Streak Bonus visual shows behind CameraView during streaks
- [ ] Combo Score / Bonus message briefly appears on screen
- [ ] If streak broken, combo effects gracefully reset

---

## Rewards & Achievements
- [ ] Success chime plays after each rep completion
- [ ] Medal popup appears after every 10 reps
- [ ] New achievements unlock properly (e.g., "3-Day Streak", "Level Up")
- [ ] Achievement popup appears when a new Routine (e.g., Core, Stretch) unlocks
- [ ] XP and Level update correctly
- [ ] Streak counter updates correctly per day

---

## Reset / Restart
- [ ] "Reset" button stops detection immediately
- [ ] UI resets (Pose Label back to "Waiting...", Reps: 0, Colors reset)
- [ ] Picker and label fade back into view after Reset
- [ ] CameraView returns to normal (no zoom, no glow)

---

# 🎯 Daily Mini Test Plan
- Launch app and check starting UI ✔️
- Run full workout session (Countdown → Detection → Combo → Rewards) ✔️
- Test reset and second session ✔️
- Force-break streak to test fallback ✔️
- Unlock at least 1 achievement ✔️
- Test on simulator + physical device ✔️

---

# 📱 Best Phone Positioning for TechnicallyPilates

To get the best experience, please follow these guidelines when setting up your device:

## 📋 Instructions

|   |   |
|---|---|
| 📏 **Distance** | Place your phone about 2-3 meters (6-10 feet) away from you. |
| 🔼 **Height** | Ideally, mount the phone around hip to chest height. A chair, low table, or adjustable stand works well. |
| 🎥 **Angle** | Tilt the phone slightly upwards, about 15°, so it captures your full body without needing to move much. |
| 💡 **Lighting** | Ensure you're in a well-lit area (natural light or strong room light). Avoid strong backlight (like bright windows behind you). |
| 🌟 **Background** | Try to stand in front of a simple background (plain wall is ideal) to make body detection easier and more accurate. |
| 📵 **Stability** | Keep the phone steady (use a tripod, or secure it against something stable). Avoid handheld usage. |
| ✅ **Pro Tip** | Test by walking back into the camera frame and checking the preview before starting detection. Your full body (including hands and feet) should be visible. |

---

# 🚀 Notes for the Day
- If UI freezes, check for animation conflicts
- If sounds don't play, ensure AVFoundation permissions
- If streak/XP not updating, debug pose rep counting
- Remember: Every rep triggers XP, every level unlocks routines!

---

# ✅ Done? 
- Celebrate with a perfect combo streak 🔥🏆

---

# 📈 Part 1: Full Mechanics + Mathematics of PoseClassifier.mlpackage

- **Input**: 4 joint angles: `leftHipAngle`, `rightHipAngle`, `leftElbowAngle`, `rightElbowAngle`
- **Process**: These angles are normalized and fed into a lightweight multi-class classifier.
- **Output**: A predicted pose label, such as `"Correct Standing Pose"` or `"Incorrect Form"`.
- **Mathematical Basis**:
  - Angles are computed using dot products and arccosine functions.
  - The model uses simple supervised classification (likely a lightweight neural network or decision tree).
  - Softmax activation produces the confidence score over pose classes.

---

# 🛠️ Part 2: Next Steps to Improve PoseClassifier.mlpackage

- Collect more diverse training data (different body types, lighting conditions).
- Expand input features (include more joints like knees, shoulders, etc.).
- Use time-series smoothing (track poses over multiple frames, not just frame-by-frame).
- Integrate a confidence threshold (only count reps if >90% confidence).
- Add more pose variations (levels of difficulty, partial poses).
- Potentially upgrade to a more complex sequence model like an LSTM or Transformer-lite if necessary.

---

# 🔄 Part 3: Full Flowchart of Pose Detection

```plaintext
Camera Feed
    ↓
Pose Detection (Vision Framework)
    ↓
Feature Extraction (Joint Angles Calculation)
    ↓
PoseClassifier.mlpackage
    ↓
Predicted Pose Label
    ↓
Feedback (Color / Sound / Animation)
    ↓
Display to User (UI updated)


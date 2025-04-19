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

# 📚 Part 1: Full Mechanics + Mathematics of PoseClassifier.mlpackage

Your `PoseClassifier.mlpackage` (originally trained via `ml_model.py`) works as follows:

## Mechanics

**Input:**  
- 6 pose features (likely key joint angles, such as hips, elbows, etc.)  
Example input: `[45.3, 120.5, 90.0, 135.0, 80.0, 110.0]`

**Neural Network Architecture:**
- **Dense Layer 1:** 16 neurons, **ReLU** activation  
- **Dense Layer 2:** 8 neurons, **ReLU** activation  
- **Dense Layer 3:** 2 neurons, **Softmax** activation

Softmax function:

\[
\text{softmax}(z_i) = \frac{e^{z_i}}{\sum_j e^{z_j}}
\]

Where \( z_i \) are the raw outputs (logits) of the final dense layer.

**Output:**
- Two probabilities:
  - Class 0 → Incorrect Pose
  - Class 1 → Correct Pose

**Prediction Decision:**
- `np.argmax(prediction)` → Picks the class (0 or 1) with the highest probability.

**Feedback Output:**
- If Class 1 (correct): `"Good pose!"`
- If Class 0 (incorrect): `"Adjust posture."`
- Confidence score = maximum probability.

---

## 🧠 Mathematics Flow

At prediction time:

**Input:**  
Vector **x** ∈ ℝ⁶

**First Dense Layer:**  
h₁ = ReLU(x × W₁ + b₁), where W₁ ∈ ℝ⁶ˣ¹⁶

**Second Dense Layer:**  
h₂ = ReLU(h₁ × W₂ + b₂), where W₂ ∈ ℝ¹⁶ˣ⁸

**Third Dense Layer:**  
h₃ = Softmax(h₂ × W₃ + b₃), where W₃ ∈ ℝ⁸ˣ²

**Output:**  
Two numbers (probabilities) summing to 1 → representing "Incorrect" and "Correct".

---

✅ **Summary:**  
This is a lightweight, fast, real-time classifier judging if a user’s pose is "good" or "needs adjustment" based on 6 input pose features.

---

# 🚀 Part 2: Next Steps to Improve PoseClassifier.mlpackage

| Step | Feature | Why? | How? |
|---|---|---|---|
| 1 | Add more input features | 6 angles is okay, but adding joint velocities or more joints boosts accuracy. | Capture frame-to-frame deltas (Δθ/Δt). |
| 2 | Multi-class Output | Instead of binary good/bad, classify specific mistakes ("Knee too low", etc.). | Train with 4-6 labeled error categories. |
| 3 | Pose Difficulty Levels | Some poses are harder — make feedback adaptable to difficulty. | Add difficulty labels during training. |
| 4 | Model Size Optimization | Shrink model size for faster CoreML execution. | Use TensorFlow Model Optimization Toolkit (tfmot). |
| 5 | Confidence Calibration | Softmax may be overconfident; calibrate probabilities. | Apply temperature scaling after training. |
| 6 | Train with Real User Data | Fine-tuning on real users massively boosts model quality. | Log anonymized real user pose data and retrain. |
| 7 | Add Time-Series Context | Single frame analysis misses motion stability. | Add 1D CNN or RNN over short frame sequences. |
| 8 | Train Pose Correction Recommender | Predict not just "wrong" but "how to fix." | Output a correction vector with the prediction. |

---

## 🛠️ Part 3: System Flowchart


```mermaid
flowchart TD
    A([App Launch 🚀]) --> B(Choose Routine 📋)
    B --> C(Start Detection ▶️)
    C --> D{Countdown ⏳}
    D --> E(3... Beep 🔊)
    E --> F(2... Beep 🔊)
    F --> G(1... Beep 🔊)
    G --> H(GO! 🔔)

    H --> I(Camera Detection Active 🎥)
    I --> J{Pose Detected? 🤔}

    J -- Yes --> K{Correct Pose? ✅❌}
    K -- Yes --> L[+1 Rep 🏋️‍♂️ Flash Effect ✨]
    K -- No --> M[Error Vibration 🔴]

    L --> N{Combo Streak? 🔥}
    N -- Yes --> O[Fire Trail Animation 🚀🔥]
    O --> P(Show "Combo Bonus!" 🎉)
    N -- No --> I

    P --> I

    M --> I

    L --> Q{10 Reps Completed? 🏆}
    Q -- Yes --> R(Medal Popup 🥇 + Achievement Unlocked 🎖️)
    Q -- No --> I

    R --> S(Reset / New Routine 🔄)
    S --> B

```



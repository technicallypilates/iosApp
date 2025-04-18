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

# 🚀 Notes for the Day
- If UI freezes, check for animation conflicts
- If sounds don't play, ensure AVFoundation permissions
- If streak/XP not updating, debug pose rep counting
- Remember: Every rep triggers XP, every level unlocks routines!

---

# ✅ Done? 
- Celebrate with a perfect combo streak 🔥🏆



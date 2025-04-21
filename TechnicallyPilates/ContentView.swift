import SwiftUI
import AVFoundation
import Vision
import UIKit

struct ContentView: View {
    @State private var poseLabel: String = "Waiting..."
    @State private var poseColor: Color = .gray
    @State private var startDetection: Bool = false
    @State private var repCount: Int = 0
    @State private var logEntries: [PoseLogEntry] = []

    @State private var selectedRoutine: Routine = .standing
    @State private var currentPoseIndex: Int = 0

    @State private var userProfile = UserProfile(name: "User1")

    @State private var pickerVisible = true
    @State private var cameraTilt = false
    @State private var cameraGlow = false

    @State private var countdownActive = false
    @State private var countdownNumber = 3

    @State private var showComboBonus = false
    @State private var currentStreak = 0

    @State private var showAchievement = false
    @State private var achievementText = ""

    @State private var showFlash = false
    @State private var showSpinner = false

    let beepPlayer = SoundPlayer()

    var body: some View {
        VStack(spacing: 16) {
            if pickerVisible {
                VStack(spacing: 8) {
                    Text("🎯 Choose Your Focus")
                        .font(.headline)
                    Picker("Routine", selection: $selectedRoutine) {
                        ForEach(userProfile.unlockedRoutines) { routine in
                            Text(routine.displayName).tag(routine)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                .padding(.top, 10)
            }

            ZStack {
                CameraView(
                    poseLabel: $poseLabel,
                    poseColor: $poseColor,
                    startDetection: $startDetection,
                    repCount: $repCount,
                    logEntries: $logEntries,
                    selectedRoutine: selectedRoutine,
                    currentPoseIndex: currentPoseIndex,
                    onNewEntry: { entry in
                        handleNewEntry(entry)
                    }
                )
                .frame(height: 300)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cameraGlow ? Color.blue.opacity(0.7) : Color.clear, lineWidth: 8)
                        .blur(radius: 4)
                        .animation(.easeInOut(duration: 0.5), value: cameraGlow)
                )
                .rotation3DEffect(.degrees(cameraTilt ? 10 : 0), axis: (x: 0.0, y: 1.0, z: 0.0))
                .scaleEffect(cameraTilt ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.8), value: cameraTilt)

                if showComboBonus {
                    FireTrailView()
                        .frame(width: 350, height: 350)
                        .offset(y: -20)
                        .transition(.scale)
                }

                if countdownActive {
                    Text(countdownNumber > 0 ? "\(countdownNumber)" : "GO!")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.red)
                        .transition(.scale)
                        .animation(.easeInOut, value: countdownNumber)
                }

                if showSpinner {
                    ProgressView("Camera Starting...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                        .transition(.opacity)
                }

                if showAchievement {
                    VStack {
                        Spacer()
                        Text("🏆 \(achievementText)")
                            .font(.title2)
                            .padding()
                            .background(Color.yellow.opacity(0.9))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                        Spacer()
                    }
                    .transition(.move(edge: .bottom))
                }

                if showFlash {
                    Color.white
                        .edgesIgnoringSafeArea(.all)
                        .opacity(0.8)
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.2), value: showFlash)
                }
            }

            VStack {
                Text("Pose: \(poseLabel)").font(.title2).foregroundColor(poseColor)
                Text("Reps: \(repCount)").font(.title3)
            }

            if !startDetection && !countdownActive {
                Button("Start Detection") {
                    beginCountdown()
                }
                .padding()
                .background(Color.green.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            Button("Reset") {
                resetSession()
            }
            .padding()
            .background(Color.red.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)

            List(logEntries) { entry in
                VStack(alignment: .leading) {
                    Text("Pose: \(entry.pose)")
                    Text("Reps: \(entry.repsCompleted)")
                    Text("Time: \(entry.timestamp.formatted(.dateTime.hour().minute().second()))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxHeight: 200)

            VStack(alignment: .leading, spacing: 6) {
                Text("XP: \(userProfile.xp)")
                Text("Level: \(userProfile.level)")
                Text("🔥 Streak: \(userProfile.streakCount) days")
                Text("🏅 Achievements: \(userProfile.unlockedAchievements.joined(separator: ", "))")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
    }

    // MARK: - Logic

    func beginCountdown() {
        pickerVisible = false
        countdownActive = true
        countdownNumber = 3
        countdownStep()
    }

    func countdownStep() {
        if countdownNumber > 0 {
            beepPlayer.playBeep()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                countdownNumber -= 1
                countdownStep()
            }
        } else {
            beepPlayer.playGo()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                countdownActive = false
                startCamera()
            }
        }
    }

    func startCamera() {
        showSpinner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSpinner = false
            startDetection = true
            cameraTilt = true
            cameraGlow = true
        }
    }

    func handleNewEntry(_ entry: PoseLogEntry) {
        userProfile.updateProgress(with: entry)

        if entry.pose.lowercased().contains("correct") {
            currentStreak += 1
            if currentStreak >= 3 {
                showComboBonus = true
                cameraTilt = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showComboBonus = false
                }
            }
            flashScreen()
        } else {
            currentStreak = 0
            cameraTilt = false
        }

        if let newUnlock = userProfile.unlockedAchievements.last {
            achievementText = newUnlock
            showAchievement = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showAchievement = false
            }
        }
    }

    func flashScreen() {
        showFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showFlash = false
        }
    }

    func resetSession() {
        startDetection = false
        repCount = 0
        poseLabel = "Waiting..."
        poseColor = .gray
        logEntries.removeAll()
        pickerVisible = true
        cameraTilt = false
        cameraGlow = false
        showComboBonus = false
        currentStreak = 0
        showAchievement = false
        showFlash = false
        showSpinner = false
    }
}

// MARK: - Sound Effects

class SoundPlayer {
    var beepSound: AVAudioPlayer?
    var goSound: AVAudioPlayer?

    init() {
        if let beep = Bundle.main.url(forResource: "beep", withExtension: "wav") {
            beepSound = try? AVAudioPlayer(contentsOf: beep)
        }
        if let go = Bundle.main.url(forResource: "go", withExtension: "wav") {
            goSound = try? AVAudioPlayer(contentsOf: go)
        }
    }

    func playBeep() {
        beepSound?.play()
    }

    func playGo() {
        goSound?.play()
    }
}

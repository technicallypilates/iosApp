import SwiftUI
import AVFoundation

// 💡 Routine + Pose definitions
struct RoutinePose {
    let name: String
    let targetReps: Int
}

enum Routine: String, CaseIterable, Identifiable {
    case standing = "Standing"
    case core = "Core"
    case stretching = "Stretching"

    var id: String { rawValue }

    var poses: [RoutinePose] {
        switch self {
        case .core:
            return [RoutinePose(name: "Correct Core Pose", targetReps: 3)]
        case .standing:
            return [RoutinePose(name: "Correct Standing Pose", targetReps: 3)]
        case .stretching:
            return [RoutinePose(name: "Correct Stretch Pose", targetReps: 3)]
        }
    }
}

struct PoseLogEntry: Codable, Identifiable {
    var id = UUID() // ✅ Made mutable
    let routine: String
    let pose: String
    let timestamp: Date
    let repsCompleted: Int
}

struct ContentView: View {
    @State private var poseLabel: String = "Waiting for pose..."
    @State private var poseColor: Color = .gray
    @State private var countdown: Int = 3
    @State private var repetitions: Int = 0
    @State private var countdownFinished = false
    @State private var holdFrames = 0

    @State private var selectedRoutine: Routine = .standing
    @State private var currentPoseIndex: Int = 0
    @State private var routineComplete = false
    @State private var routineSelected = false
    @State private var showingLog = false

    @State private var progressLog: [PoseLogEntry] = [] {
        didSet { saveProgressLog() }
    }

    let speechCoach = SpeechCoach()  // 🎧 Already defined in SpeechCoach.swift

    var body: some View {
        ZStack {
            if routineSelected {
                if countdownFinished {
                    CameraView(
                        poseLabel: $poseLabel,
                        poseColor: $poseColor,
                        startDetection: $countdownFinished, // ✅ Binding fixed
                        selectedRoutine: selectedRoutine
                    )
                    .edgesIgnoringSafeArea(.all)
                    .onChange(of: poseLabel) { newValue in
                        guard !routineComplete else { return }

                        let currentPose = selectedRoutine.poses[currentPoseIndex]

                        if newValue.lowercased().contains(currentPose.name.lowercased()) {
                            if repetitions == 0 && holdFrames == 0 {
                                speechCoach.speak("Start \(currentPose.name)")
                            }

                            holdFrames += 1
                            if holdFrames == 10 {
                                repetitions += 1
                                holdFrames = 0
                                AudioServicesPlaySystemSound(SystemSoundID(1013))

                                if repetitions >= currentPose.targetReps {
                                    progressLog.append(PoseLogEntry(
                                        routine: selectedRoutine.rawValue,
                                        pose: currentPose.name,
                                        timestamp: Date(),
                                        repsCompleted: currentPose.targetReps
                                    ))

                                    repetitions = 0
                                    currentPoseIndex += 1

                                    if currentPoseIndex >= selectedRoutine.poses.count {
                                        routineComplete = true
                                        speechCoach.speak("Routine complete. Great job!")
                                    }
                                }
                            }
                        } else {
                            holdFrames = 0
                        }
                    }
                } else {
                    Color.black.edgesIgnoringSafeArea(.all)
                }

                VStack {
                    if countdownFinished {
                        HStack {
                            Text("Reps: \(repetitions)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading)
                            Spacer()
                        }

                        Spacer()

                        Text(poseLabel)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(poseColor.opacity(0.8))
                            .cornerRadius(12)
                            .padding(.bottom, 10)

                        if routineComplete {
                            Text("✅ Routine Complete!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .padding()
                        }

                        Button("🔄 Restart Routine") {
                            countdown = 3
                            countdownFinished = false
                            repetitions = 0
                            currentPoseIndex = 0
                            routineComplete = false
                            routineSelected = false
                            holdFrames = 0
                        }
                        .padding(.bottom)
                    } else {
                        Spacer()
                        Text("\(countdown)")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            } else {
                VStack {
                    Text("🧘‍♀️ Select Your Routine")
                        .font(.largeTitle)
                        .padding()

                    Picker("Routine", selection: $selectedRoutine) {
                        ForEach(Routine.allCases) { routine in
                            Text(routine.rawValue).tag(routine)
                        }
                    }
                    .pickerStyle(.wheel)
                    .padding()

                    Button("Start") {
                        routineSelected = true
                        startCountdown()
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("📖 View Progress Log") {
                        showingLog = true
                    }
                    .font(.subheadline)
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .onAppear { loadProgressLog() }
        .sheet(isPresented: $showingLog) {
            PoseLogView(logEntries: progressLog)
        }
    }

    func startCountdown() {
        countdown = 3
        countdownFinished = false
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                countdownFinished = true
            }
        }
    }

    func saveProgressLog() {
        do {
            let url = getLogFileURL()
            let data = try JSONEncoder().encode(progressLog)
            try data.write(to: url)
        } catch {
            print("⚠️ Failed to save progress log: \(error)")
        }
    }

    func loadProgressLog() {
        do {
            let url = getLogFileURL()
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([PoseLogEntry].self, from: data)
            progressLog = decoded
        } catch {
            print("⚠️ No existing log found or failed to decode: \(error)")
        }
    }

    func getLogFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("PoseLog.json")
    }
}



import SwiftUI
import FirebaseFirestore

struct RoutineExecutionView: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode

    let routine: Routine

    @State private var currentPoseIndex = 0
    @State private var showingCompletion = false
    @State private var poseAccuracy: Double = 0.0
    @State private var repsCompleted = 0
    @State private var isTracking = false

    var body: some View {
        VStack {
            if currentPoseIndex < routine.poses.count {
                let currentPose = routine.poses[currentPoseIndex]

                PoseExecutionView(
                    pose: currentPose,
                    accuracy: $poseAccuracy,
                    repsCompleted: $repsCompleted,
                    isTracking: $isTracking
                )

                CameraView(
                    poseLabel: .constant(currentPose.name),
                    poseColor: .constant(.green),
                    startDetection: $isTracking,
                    repCount: $repsCompleted,
                    logEntries: .constant([]),
                    poseAccuracy: $poseAccuracy,
                    selectedRoutine: routine,
                    currentPoseIndex: currentPoseIndex,
                    onNewEntry: { entry in
                        if repsCompleted >= currentPose.repetitions {
                            Task {
                                await completeCurrentPose()
                            }
                        }
                    }
                )
            } else {
                CompletionView(routine: routine)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
            }
        }
        .navigationTitle(routine.name)
    }

    private func completeCurrentPose() async {
        guard currentPoseIndex < routine.poses.count else { return }

        let currentPose = routine.poses[currentPoseIndex]

        do {
            try await authManager.updatePoseAccuracy(
                poseId: currentPose.id,
                routineId: routine.id,
                accuracyScore: Int(poseAccuracy * 100),
                repsCompleted: repsCompleted
            )

            currentPoseIndex += 1
            poseAccuracy = 0.0
            repsCompleted = 0
            isTracking = false

            if currentPoseIndex >= routine.poses.count {
                showingCompletion = true
            }
        } catch {
            print("Error updating pose accuracy: \(error)")
        }
    }
}

struct PoseExecutionView: View {
    let pose: Pose
    @Binding var accuracy: Double
    @Binding var repsCompleted: Int
    @Binding var isTracking: Bool

    var body: some View {
        VStack {
            Text(pose.name)
                .font(.title)

            Text("Accuracy: \(Int(accuracy * 100))%")
                .font(.headline)
                .foregroundColor(accuracy > 0.6 ? .green : .red)
                .scaleEffect(1 + CGFloat(accuracy) * 0.1)
                .animation(.easeInOut(duration: 0.2), value: accuracy)

            Text("Reps Completed: \(repsCompleted)")
                .font(.headline)

            Button(action: {
                isTracking.toggle()
            }) {
                Text(isTracking ? "Stop Tracking" : "Start Tracking")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTracking ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct CompletionView: View {
    let routine: Routine
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Routine Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Great job! You've completed \(routine.name)")
                .font(.headline)

            Button("Return to Routines") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

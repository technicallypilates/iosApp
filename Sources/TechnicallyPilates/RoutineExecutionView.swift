import SwiftUI

struct RoutineExecutionView: View {
    let routine: Routine
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPoseIndex = 0
    @State private var isCompleted = false
    
    var body: some View {
        VStack {
            if currentPoseIndex < routine.poses.count {
                PoseExecutionView(
                    pose: routine.poses[currentPoseIndex],
                    onComplete: {
                        if currentPoseIndex < routine.poses.count - 1 {
                            currentPoseIndex += 1
                        } else {
                            isCompleted = true
                        }
                    }
                )
            } else {
                CompletionView(routine: routine)
            }
        }
        .navigationBarTitle(routine.name, displayMode: .inline)
        .navigationBarItems(trailing: Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        })
    }
}

struct PoseExecutionView: View {
    let pose: Pose
    let onComplete: () -> Void
    @State private var timer: Timer?
    @State private var timeRemaining: TimeInterval
    
    init(pose: Pose, onComplete: @escaping () -> Void) {
        self.pose = pose
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: pose.duration)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(pose.name)
                .font(.title)
                .bold()
            
            Text(pose.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("\(Int(timeRemaining)) seconds remaining")
                .font(.headline)
            
            Button(action: onComplete) {
                Text("Complete")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                onComplete()
            }
        }
    }
}

struct CompletionView: View {
    let routine: Routine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Routine Completed!")
                .font(.title)
                .bold()
            
            Text("Great job completing \(routine.name)!")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
    }
}

struct RoutineExecutionView_Previews: PreviewProvider {
    static let samplePoses = [
        Pose(
            name: "Plank",
            description: "Hold a plank position",
            category: "Core",
            difficulty: 2,
            instructions: ["Start in a push-up position", "Keep your body straight", "Hold for the duration"],
            benefits: ["Strengthens core", "Improves posture", "Builds endurance"],
            modifications: ["Drop to knees", "Use elbows instead of hands"],
            contraindications: ["Wrist issues", "Shoulder problems"],
            duration: 60.0,
            repetitions: 1
        ),
        Pose(
            name: "Push-up",
            description: "Perform push-ups",
            category: "Upper Body",
            difficulty: 3,
            instructions: ["Start in plank position", "Lower body with control", "Push back up"],
            benefits: ["Builds upper body strength", "Improves core stability"],
            modifications: ["Knee push-ups", "Incline push-ups"],
            contraindications: ["Shoulder injuries", "Wrist pain"],
            duration: 30.0,
            repetitions: 10
        )
    ]
    
    static var previews: some View {
        NavigationView {
            RoutineExecutionView(routine: Routine(
                name: "Sample Routine",
                description: "A sample routine for preview",
                category: "Preview",
                poses: samplePoses,
                duration: 300.0,
                difficulty: 1,
                isFavorite: false
            ))
        }
    }
} 
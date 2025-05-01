import SwiftUI

struct RoutineExecutionView: View {
    let routine: Routine
    @State private var currentPoseIndex = 0
    @State private var showingPoseDetails = false
    
    var body: some View {
        VStack {
            if currentPoseIndex < routine.exercises.count {
                ExerciseView(
                    exercise: routine.exercises[currentPoseIndex],
                    onComplete: {
                        if currentPoseIndex < routine.exercises.count - 1 {
                            currentPoseIndex += 1
                        }
                    }
                )
            } else {
                CompletionView(routine: routine)
            }
        }
        .navigationTitle(routine.name)
    }
}

struct ExerciseView: View {
    let exercise: Exercise
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            Text(exercise.name)
                .font(.title)
            
            // Exercise visualization or camera preview would go here
            
            Button("Complete Exercise") {
                onComplete()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct CompletionView: View {
    let routine: Routine
    
    var body: some View {
        VStack {
            Text("Congratulations!")
                .font(.title)
            Text("You've completed \(routine.name)")
                .font(.headline)
            
            // Additional completion stats would go here
        }
    }
}

struct RoutineExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExercises = [
            Exercise(name: "Exercise 1", description: "Sample exercise 1"),
            Exercise(name: "Exercise 2", description: "Sample exercise 2")
        ]
        
        let sampleRoutine = Routine(
            name: "Sample Routine",
            description: "A sample routine",
            exercises: sampleExercises,
            duration: 1800,
            difficulty: .beginner,
            category: .strength
        )
        
        RoutineExecutionView(routine: sampleRoutine)
    }
} 
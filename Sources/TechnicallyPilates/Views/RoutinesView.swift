import SwiftUI

let sampleRoutine = Routine(
    id: UUID(),
    name: "Morning Stretch",
    description: "A gentle routine to start your day",
    category: "Warm-up",
    poses: [],
    duration: 600,
    difficulty: 1,
    isFavorite: false
)

struct NewRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var routineName = ""
    @State private var routineDescription = ""
    @State private var routineCategory = "General"
    @State private var selectedPoses: [Pose] = []
    @State private var duration: TimeInterval = 600 // 10 minutes default
    @State private var difficulty = 1
    @State private var showingPosePicker = false
    
    let categories = ["General", "Warm-up", "Core", "Strength", "Flexibility", "Cool-down"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Routine Details")) {
                    TextField("Name", text: $routineName)
                    TextField("Description", text: $routineDescription)
                    Picker("Category", selection: $routineCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Duration and Difficulty")) {
                    Stepper(value: $duration, in: 300...3600, step: 300) {
                        Text("Duration: \(Int(duration/60)) minutes")
                    }
                    Stepper(value: $difficulty, in: 1...5) {
                        Text("Difficulty: \(difficulty)")
                    }
                }
                
                Section(header: Text("Poses")) {
                    Button(action: {
                        showingPosePicker = true
                    }) {
                        HStack {
                            Text("Select Poses")
                            Spacer()
                            Text("\(selectedPoses.count) selected")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    ForEach(selectedPoses) { pose in
                        Text(pose.name)
                    }
                }
            }
            .navigationTitle("New Routine")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let newRoutine = Routine(
                        id: UUID(),
                        name: routineName,
                        description: routineDescription,
                        category: routineCategory,
                        poses: selectedPoses,
                        duration: duration,
                        difficulty: difficulty,
                        isFavorite: false
                    )
                    // Add the new routine to your data store here
                    dismiss()
                }
            )
            .sheet(isPresented: $showingPosePicker) {
                PosePickerView(selectedPoses: $selectedPoses)
            }
        }
    }
} 
import SwiftUI
import FirebaseFirestore

struct RoutinesView: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var authManager: AuthManager
    @State private var showingNewRoutine = false
    @State private var selectedCategory: String?
    @State private var showingUnlockAnimation = false
    @State private var unlockedRoutine: Routine?

    @State private var newRoutineName = ""
    @State private var newRoutineDescription = ""

    var fullRollUpPose: Pose {
        Pose(
            id: UUID(uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF")!,
            name: "Full Roll-Up",
            description: "A controlled spinal articulation to strengthen the core.",
            category: "Core",
            difficulty: 2,
            instructions: [
                "Lie flat on your back with arms overhead.",
                "Inhale to prepare, exhale to roll up one vertebra at a time.",
                "Reach over the toes and return slowly."
            ],
            benefits: ["Improves core strength", "Enhances spinal mobility"],
            modifications: ["Bend knees slightly", "Hold behind thighs for support"],
            contraindications: ["Severe back pain", "Sciatica"],
            duration: 30.0,
            repetitions: 5,
            targetAngles: [
                "leftHipAngle": 90.0,
                "rightHipAngle": 90.0,
                "leftElbowAngle": 180.0,
                "rightElbowAngle": 180.0,
                "leftKneeAngle": 180.0,
                "rightKneeAngle": 180.0,
                "spineAngle": 0.0,
                "shoulderAlignment": 0.0,
                "hipAlignment": 0.0
            ]
        )
    }

    var beginnerRoutine: Routine {
        Routine(
            id: UUID(),
            name: "Beginner's Flow",
            description: "Perfect for those new to Pilates",
            category: "Core",
            poses: [fullRollUpPose],
            duration: 180,
            difficulty: 1,
            isFavorite: true,
            isUnlocked: true
        )
    }

    var filteredRoutines: [Routine] {
        let routinesWithTest = [beginnerRoutine] + viewModel.routines
        return routinesWithTest.filter { routine in
            selectedCategory == nil || routine.category == selectedCategory
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredRoutines) { routine in
                    RoutineCard(routine: routine)
                        .onTapGesture {
                            if routine.isUnlocked {
                                viewModel.selectedRoutine = routine
                            }
                        }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewRoutine = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewRoutine) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Create New Routine")
                        .font(.title2)
                        .bold()

                    TextField("Routine Name", text: $newRoutineName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Description", text: $newRoutineDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Save Routine") {
                        let newRoutine = Routine(
                            id: UUID(),
                            name: newRoutineName,
                            description: newRoutineDescription,
                            category: "Core",
                            poses: [fullRollUpPose],
                            duration: 180,
                            difficulty: 1,
                            isFavorite: false,
                            isUnlocked: true
                        )
                        viewModel.routines.append(newRoutine)
                        newRoutineName = ""
                        newRoutineDescription = ""
                        showingNewRoutine = false
                    }
                    .disabled(newRoutineName.isEmpty || newRoutineDescription.isEmpty)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Spacer()
                }
                .padding()
            }
            .sheet(item: $viewModel.selectedRoutine) { routine in
                RoutineExecutionView(routine: routine)
            }
        }
    }
}


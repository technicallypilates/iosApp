import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State private var selectedRoutine: Routine?
    @State private var showingNewRoutineSheet = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.routines) { routine in
                    RoutineRow(routine: routine)
                        .onTapGesture {
                            selectedRoutine = routine
                        }
                }
                .onDelete(perform: deleteRoutines)
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewRoutineSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $selectedRoutine) { routine in
                RoutineDetailView(routine: routine)
            }
            .sheet(isPresented: $showingNewRoutineSheet) {
                NewRoutineView()
            }
        }
    }
    
    private func deleteRoutines(at offsets: IndexSet) {
        for index in offsets {
            let routine = viewModel.routines[index]
            viewModel.deleteRoutine(routine)
        }
    }
}

struct RoutineRow: View {
    let routine: Routine
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(routine.name)
                    .font(.headline)
                Text(routine.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(routine.poses.count) poses")
                    .font(.caption)
                Text("\(Int(routine.duration)) min")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

struct RoutineDetailView: View {
    let routine: Routine
    @Environment(\.presentationMode) var presentationMode
    @State private var showingStartRoutine = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text(routine.name)
                            .font(.title)
                            .bold()
                        Text(routine.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 30) {
                        StatItem(title: "Duration", value: "\(Int(routine.duration)) min")
                        StatItem(title: "Difficulty", value: "\(routine.difficulty)/5")
                        StatItem(title: "Poses", value: "\(routine.poses.count)")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Poses
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Poses")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ForEach(routine.poses) { pose in
                            PoseRow(pose: pose)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarItems(trailing: Button(action: {
                showingStartRoutine = true
            }) {
                Text("Start")
                    .bold()
            })
            .sheet(isPresented: $showingStartRoutine) {
                RoutineExecutionView(routine: routine)
            }
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
        }
    }
}

struct PoseRow: View {
    let pose: Pose
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(pose.name)
                    .font(.headline)
                Text(pose.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(pose.repetitions) reps")
                    .font(.caption)
                Text("\(Int(pose.duration)) sec")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct NewRoutineView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ViewModel
    @State private var name = ""
    @State private var description = ""
    @State private var selectedPoses: Set<Pose> = []
    @State private var showingPosePicker = false
    @State private var category = "Custom"
    @State private var difficulty = 1
    @State private var duration = 0.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Routine Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Duration (minutes)", value: $duration, format: .number)
                    TextField("Difficulty", value: $difficulty, format: .number)
                }
                
                Section(header: Text("Selected Poses")) {
                    ForEach(Array(selectedPoses)) { pose in
                        Text(pose.name)
                    }
                    .onDelete { indexSet in
                        let poses = Array(selectedPoses)
                        for index in indexSet {
                            selectedPoses.remove(poses[index])
                        }
                    }
                }
                
                Section {
                    Button("Add Poses") {
                        showingPosePicker = true
                    }
                }
            }
            .navigationTitle("New Routine")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveRoutine()
                }
                .disabled(name.isEmpty || selectedPoses.isEmpty)
            )
            .sheet(isPresented: $showingPosePicker) {
                PosePickerView(selectedPoses: $selectedPoses)
            }
        }
    }
    
    private func saveRoutine() {
        let newRoutine = Routine(
            id: UUID(),
            name: name,
            description: description,
            category: category,
            poses: Array(selectedPoses),
            duration: TimeInterval(duration * 60),
            difficulty: difficulty
        )
        viewModel.addRoutine(newRoutine)
        presentationMode.wrappedValue.dismiss()
    }
}

struct PosePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ViewModel
    @Binding var selectedPoses: Set<Pose>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.poses) { pose in
                    HStack {
                        Text(pose.name)
                        Spacer()
                        if selectedPoses.contains(pose) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedPoses.contains(pose) {
                            selectedPoses.remove(pose)
                        } else {
                            selectedPoses.insert(pose)
                        }
                    }
                }
            }
            .navigationTitle("Select Poses")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct RoutinesView_Previews: PreviewProvider {
    static var previews: some View {
        RoutinesView()
            .environmentObject(ViewModel())
    }
} 
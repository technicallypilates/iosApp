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
                    .environmentObject(viewModel)
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
                Text("\(routine.exercises.count) exercises")
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
                    VStack(alignment: .leading, spacing: 10) {
                        Text(routine.name)
                            .font(.title)
                            .bold()
                        Text(routine.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 30) {
                        StatItem(title: "Duration", value: "\(Int(routine.duration)) min")
                        StatItem(title: "Difficulty", value: routine.difficulty.rawValue)
                        StatItem(title: "Exercises", value: "\(routine.exercises.count)")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Exercises")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        ForEach(routine.exercises) { exercise in
                            ExerciseRow(exercise: exercise)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarItems(trailing: Button("Start") {
                showingStartRoutine = true
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

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.name)
                    .font(.headline)
                Text(exercise.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(exercise.repetitions) reps")
                    .font(.caption)
                Text("\(Int(exercise.duration)) sec")
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
    @State private var selectedExercises: [Exercise] = []
    @State private var showingExercisePicker = false
    @State private var category = Category.mixed
    @State private var difficulty = Difficulty.beginner
    @State private var duration = 0.0

    var body: some View {
        NavigationView {
            Form(content: {
                Section(header: Text("Routine Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Duration (minutes)", value: $duration, format: .number)

                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                }

                Section(header: Text("Selected Exercises")) {
                    ForEach(selectedExercises) { exercise in
                        Text(exercise.name)
                    }
                    .onDelete { indexSet in
                        selectedExercises.remove(atOffsets: indexSet)
                    }
                }

                Section {
                    Button("Add Exercises") {
                        showingExercisePicker = true
                    }
                }
            })
            .navigationTitle("New Routine")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveRoutine()
                }.disabled(name.isEmpty || selectedExercises.isEmpty)
            )
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $selectedExercises)
                    .environmentObject(viewModel)
            }
        }
    }

    private func saveRoutine() {
        let newRoutine = Routine(
            name: name,
            description: description,
            exercises: selectedExercises,
            duration: TimeInterval(duration * 60),
            difficulty: difficulty,
            category: category
        )
        viewModel.addRoutine(newRoutine)
        presentationMode.wrappedValue.dismiss()
    }
}

struct ExercisePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ViewModel
    @Binding var selectedExercises: [Exercise]

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.exercises) { exercise in
                    HStack {
                        Text(exercise.name)
                        Spacer()
                        if selectedExercises.contains(where: { $0.id == exercise.id }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
                            selectedExercises.remove(at: index)
                        } else {
                            selectedExercises.append(exercise)
                        }
                    }
                }
            }
            .navigationTitle("Select Exercises")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}


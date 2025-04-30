import SwiftUI
import FirebaseFirestore

struct Routine: Identifiable {
    var id: String
    var name: String
    var description: String
    var exercises: [Exercise]
    var duration: Int
    var difficulty: String
}

struct Exercise: Identifiable {
    var id: String
    var name: String
    var description: String
    var duration: Int
    var imageURL: String?
}

class RoutinesViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    private let db = Firestore.firestore()
    
    func fetchRoutines() {
        db.collection("routines").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching routines: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self?.routines = documents.compactMap { document in
                let data = document.data()
                return Routine(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    exercises: (data["exercises"] as? [[String: Any]] ?? []).compactMap { exerciseData in
                        Exercise(
                            id: exerciseData["id"] as? String ?? UUID().uuidString,
                            name: exerciseData["name"] as? String ?? "",
                            description: exerciseData["description"] as? String ?? "",
                            duration: exerciseData["duration"] as? Int ?? 0,
                            imageURL: exerciseData["imageURL"] as? String
                        )
                    },
                    duration: data["duration"] as? Int ?? 0,
                    difficulty: data["difficulty"] as? String ?? ""
                )
            }
        }
    }
}

struct RoutinesView: View {
    @StateObject private var viewModel = RoutinesViewModel()
    @State private var showingNewRoutine = false
    
    var body: some View {
        NavigationView {
            List(viewModel.routines) { routine in
                NavigationLink(destination: RoutineDetailView(routine: routine)) {
                    VStack(alignment: .leading) {
                        Text(routine.name)
                            .font(.headline)
                        Text(routine.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack {
                            Text("\(routine.duration) min")
                            Spacer()
                            Text(routine.difficulty)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                Button(action: { showingNewRoutine = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingNewRoutine) {
                NewRoutineView()
            }
            .onAppear {
                viewModel.fetchRoutines()
            }
        }
    }
}

struct RoutineDetailView: View {
    let routine: Routine
    
    var body: some View {
        List {
            Section(header: Text("Description")) {
                Text(routine.description)
            }
            
            Section(header: Text("Exercises")) {
                ForEach(routine.exercises) { exercise in
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.headline)
                        Text(exercise.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(exercise.duration) seconds")
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(routine.name)
    }
}

struct NewRoutineView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var duration = 30
    @State private var difficulty = "Beginner"
    @State private var exercises: [Exercise] = []
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Routine Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    Stepper("Duration: \(duration) minutes", value: $duration, in: 5...120, step: 5)
                    Picker("Difficulty", selection: $difficulty) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                }
                
                Section(header: Text("Exercises")) {
                    ForEach(exercises) { exercise in
                        Text(exercise.name)
                    }
                    Button("Add Exercise") {
                        // TODO: Implement exercise selection
                    }
                }
            }
            .navigationTitle("New Routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoutine()
                    }
                }
            }
        }
    }
    
    private func saveRoutine() {
        let routine = Routine(
            id: UUID().uuidString,
            name: name,
            description: description,
            exercises: exercises,
            duration: duration,
            difficulty: difficulty
        )
        
        db.collection("routines").document(routine.id).setData([
            "name": routine.name,
            "description": routine.description,
            "exercises": routine.exercises.map { exercise in
                [
                    "id": exercise.id,
                    "name": exercise.name,
                    "description": exercise.description,
                    "duration": exercise.duration,
                    "imageURL": exercise.imageURL as Any
                ]
            },
            "duration": routine.duration,
            "difficulty": routine.difficulty
        ]) { error in
            if let error = error {
                print("Error saving routine: \(error.localizedDescription)")
            } else {
                dismiss()
            }
        }
    }
}

#Preview {
    RoutinesView()
} 
import SwiftUI

struct PoseLogView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            List {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                ForEach(viewModel.logEntries.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { entry in
                    VStack(alignment: .leading) {
                        Text(viewModel.getExerciseById(entry.poseId)?.name ?? "Unknown Pose")
                            .font(.headline)
                        HStack {
                            Text("\(entry.repsCompleted) reps")
                                .font(.subheadline)
                            Spacer()
                            Text(entry.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Pose Log")
        }
    }
}

struct PoseLogView_Previews: PreviewProvider {
    static var previews: some View {
        PoseLogView()
            .environmentObject(ViewModel()) // ✅ Needed to resolve @EnvironmentObject
    }
}


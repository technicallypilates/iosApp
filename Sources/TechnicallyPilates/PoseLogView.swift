import SwiftUI

struct PoseLogView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                List {
                    ForEach(viewModel.poseLog.sorted(by: { $0.date > $1.date })) { entry in
                        if let pose = viewModel.getPoseById(entry.poseId) {
                            VStack(alignment: .leading) {
                                Text(pose.name)
                                    .font(.headline)
                                Text("\(entry.repsCompleted) reps")
                                    .font(.subheadline)
                                Text(entry.timestamp, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pose Log")
        }
    }
}

struct PoseLogView_Previews: PreviewProvider {
    static var previews: some View {
        PoseLogView()
            .environmentObject(ViewModel())
    }
} 
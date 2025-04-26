import SwiftUI

struct PoseLogView: View {
    let logEntries: [PoseLogEntry]

    var body: some View {
        NavigationView {
            List(logEntries.sorted { $0.timestamp > $1.timestamp }) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.pose)
                        .font(.headline)
                    Text("Routine: \(entry.routine)")
                        .font(.subheadline)
                    Text("Reps Completed: \(entry.repsCompleted)")
                        .font(.subheadline)
                    Text("🕒 \(entry.timestamp.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("📈 Pose Progress")
        }
    }
}


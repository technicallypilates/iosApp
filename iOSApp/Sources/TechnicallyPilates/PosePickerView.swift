import SwiftUI

struct PosePickerView: View {
    @Binding var selectedPoses: [Pose]
    @Environment(\.dismiss) private var dismiss
    
    let allPoses: [Pose] = [
        Pose(name: "Pilates Stance",
             description: "Basic standing position",
             category: "Foundation",
             difficulty: 1,
             instructions: ["Stand with feet hip-width apart", "Engage core", "Shoulders relaxed"],
             benefits: ["Improves posture", "Builds body awareness"],
             modifications: ["Widen stance if needed"],
             contraindications: ["None"],
             duration: 60.0,
             repetitions: 1),
        // Add more preset poses as needed
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allPoses) { pose in
                    PoseRow(pose: pose, isSelected: selectedPoses.contains(pose))
                        .onTapGesture {
                            if selectedPoses.contains(pose) {
                                selectedPoses.removeAll { $0.id == pose.id }
                            } else {
                                selectedPoses.append(pose)
                            }
                        }
                }
            }
            .navigationTitle("Select Poses")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct PoseRow: View {
    let pose: Pose
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(pose.name)
                    .font(.headline)
                Text(pose.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
    }
}

#Preview {
    PosePickerView(selectedPoses: .constant([]))
} 
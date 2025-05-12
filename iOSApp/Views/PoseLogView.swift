import SwiftUI
import UIKit

struct PoseLogView: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedDate = Date()
    @State private var isSharing = false
    @State private var shareController: UIActivityViewController?

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()

                List {
                    ForEach(viewModel.poseLog.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
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

                Button("Share My Score") {
                    guard let user = authManager.currentUser else { return }

                    let progress = SocialManager.UserProgress(
                        level: user.level,
                        xp: user.xp,
                        streakCount: user.streakCount,
                        routinesCompleted: viewModel.poseLog.count
                    )

                    shareController = SocialManager.shared.shareProgress(progress)
                    isSharing = true
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .sheet(isPresented: $isSharing) {
                    if let controller = shareController {
                        ShareSheet(activityController: controller)
                    }
                }
            }
            .navigationTitle("Pose Log")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityController: UIActivityViewController

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return activityController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PoseLogView_Previews: PreviewProvider {
    static var previews: some View {
        PoseLogView()
            .environmentObject(ViewModel())
            .environmentObject(AuthManager.shared)
    }
}


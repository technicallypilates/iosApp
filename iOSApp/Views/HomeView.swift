import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ViewModel
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedRoutine: Routine?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let user = authManager.currentUser {
                        UserProgressCard(user: user)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Access")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(viewModel.routines) { routine in
                                    RoutineCard(routine: routine)
                                        .frame(width: 160, height: 90)
                                        .onTapGesture {
                                            selectedRoutine = routine
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Activity")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        if viewModel.poseLog.isEmpty {
                            Text("No activity yet. Complete a routine to get started!")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .padding(.horizontal)
                        } else {
                            ForEach(viewModel.poseLog.prefix(5)) { entry in
                                if let pose = viewModel.getPoseById(entry.poseId) {
                                    ActivityRow(pose: pose, entry: entry)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .sheet(item: $selectedRoutine) { routine in
                RoutineExecutionView(routine: routine)
            }
        }
    }
}

struct UserProgressCard: View {
    let user: UserProfile

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(user.name)
                        .font(.title2)
                        .bold()
                }
                Spacer()
                if let data = user.profileImageData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                }
            }

            HStack(spacing: 20) {
                ProgressItem(title: "Level", value: "\(user.level)")
                ProgressItem(title: "XP", value: "\(user.xp)")
                ProgressItem(title: "Streak", value: "\(user.streakCount)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct ProgressItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
                .bold()
        }
    }
}

struct ActivityRow: View {
    let pose: Pose
    let entry: PoseLogEntry

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(pose.name)
                    .font(.headline)
                Text(dateFormatter.string(from: entry.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(entry.repsCompleted) reps")
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(ViewModel())
    }
}

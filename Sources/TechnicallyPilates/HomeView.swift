import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ViewModel
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedRoutine: Routine?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // User Progress Section
                    if let user = authManager.currentUser {
                        UserProgressCard(user: user)
                    }
                    
                    // Quick Access Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Access")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(viewModel.routines) { routine in
                                    RoutineCard(routine: routine)
                                        .onTapGesture {
                                            selectedRoutine = routine
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Activity Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Activity")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ForEach(viewModel.poseLog.prefix(5).map { $0 }) { entry in
                            if let pose = viewModel.getPoseById(entry.poseId) {
                                ActivityRow(pose: pose, entry: entry)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .sheet(item: $selectedRoutine) { routine in
                RoutineDetailView(routine: routine)
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
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
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

struct RoutineCard: View {
    let routine: Routine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(routine.name)
                .font(.headline)
            Text("\(routine.poses.count) poses")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 150, height: 100)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ActivityRow: View {
    let pose: Pose
    let entry: PoseLogEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(pose.name)
                    .font(.headline)
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(entry.repetitions) reps")
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
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // User Stats
                    VStack(alignment: .leading) {
                        Text("Welcome, \(viewModel.userProfile.name)!")
                            .font(.title)
                            .padding(.bottom, 5)
                        
                        HStack {
                            StatView(title: "Level", value: "\(viewModel.userProfile.level)")
                            StatView(title: "XP", value: "\(viewModel.userProfile.xp)")
                            StatView(title: "Streak", value: "\(viewModel.userProfile.streakCount) days")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Recent Activity
                    VStack(alignment: .leading) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        ForEach(viewModel.logEntries.prefix(5)) { entry in
                            HStack {
                                Text(entry.poseName)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(entry.reps) reps")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Favorite Routines
                    VStack(alignment: .leading) {
                        Text("Favorite Routines")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(viewModel.userProfile.favoriteRoutines) { routine in
                                    RoutineCard(routine: routine)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}

struct StatView: View {
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
        .frame(maxWidth: .infinity)
    }
}

struct RoutineCard: View {
    let routine: Routine
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(routine.name)
                .font(.headline)
            Text("\(routine.exercises.count) exercises")
                .font(.caption)
                .foregroundColor(.gray)
            Text(routine.difficulty.rawValue)
                .font(.caption)
                .padding(5)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(5)
        }
        .padding()
        .frame(width: 150)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(ViewModel())
    }
} 
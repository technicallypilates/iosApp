import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ViewModel
    @StateObject private var authManager = AuthManager.shared
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = authManager.currentUser {
                        // Profile Header
                        ProfileHeader(user: user)
                        
                        // Stats Section
                        StatsSection(user: user)
                        
                        // Achievements Section
                        AchievementsSection(achievements: user.unlockedAchievements.map { $0.name })
                        
                        // Logout Button
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            Text("Log Out")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button(action: {
                showingEditProfile = true
            }) {
                Image(systemName: "pencil")
            })
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Log Out")) {
                        authManager.signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct ProfileHeader: View {
    let user: UserProfile
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(user.name)
                .font(.title)
                .bold()
            
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct StatsSection: View {
    let user: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Stats")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                StatCard(title: "Level", value: "\(user.level)")
                StatCard(title: "XP", value: "\(user.xp)")
                StatCard(title: "Streak", value: "\(user.streakCount)")
            }
            .padding(.horizontal)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct AchievementsSection: View {
    let achievements: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Achievements")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            if achievements.isEmpty {
                Text("No achievements yet")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                ForEach(achievements, id: \.self) { achievement in
                    AchievementRow(title: achievement)
                }
            }
        }
    }
}

struct AchievementRow: View {
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text(title)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: ViewModel
    @StateObject private var authManager = AuthManager.shared
    @State private var name: String
    @State private var goals: [String]
    @State private var newGoal = ""
    
    init() {
        if let user = AuthManager.shared.currentUser {
            _name = State(initialValue: user.name)
            _goals = State(initialValue: user.goals)
        } else {
            _name = State(initialValue: "")
            _goals = State(initialValue: [])
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Goals")) {
                    ForEach(goals, id: \.self) { goal in
                        Text(goal)
                    }
                    .onDelete { indexSet in
                        goals.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("New Goal", text: $newGoal)
                        Button("Add") {
                            if !newGoal.isEmpty {
                                goals.append(newGoal)
                                newGoal = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
            )
        }
    }
    
    private func saveProfile() {
        if var user = authManager.currentUser {
            user.name = name
            user.goals = goals
            viewModel.updateUserProfile(user)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(ViewModel())
    }
} 
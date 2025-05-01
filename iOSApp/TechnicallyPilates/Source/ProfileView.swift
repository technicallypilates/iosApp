import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Profile")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(viewModel.userProfile.name)
                                .font(.headline)
                            Text(viewModel.userProfile.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Stats")) {
                    HStack {
                        Text("Level")
                        Spacer()
                        Text("\(viewModel.userProfile.level)")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("XP")
                        Spacer()
                        Text("\(viewModel.userProfile.xp)")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Streak")
                        Spacer()
                        Text("\(viewModel.userProfile.streakCount) days")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Achievements")) {
                    ForEach(viewModel.userProfile.achievements) { achievement in
                        HStack {
                            Image(systemName: achievement.isUnlocked ? "star.fill" : "star")
                                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                            Text(achievement.name)
                            Spacer()
                            if achievement.isUnlocked {
                                Text("Unlocked")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                Button("Edit") {
                    showingEditProfile = true
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var email: String
    
    init() {
        let viewModel = ViewModel()
        _name = State(initialValue: viewModel.userProfile.name)
        _email = State(initialValue: viewModel.userProfile.email)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let updatedProfile = UserProfile(
                        id: viewModel.userProfile.id,
                        name: name,
                        email: email,
                        level: viewModel.userProfile.level,
                        xp: viewModel.userProfile.xp,
                        streakCount: viewModel.userProfile.streakCount,
                        goals: viewModel.userProfile.goals,
                        achievements: viewModel.userProfile.achievements,
                        unlockedAchievements: viewModel.userProfile.unlockedAchievements,
                        lastWorkoutDate: viewModel.userProfile.lastWorkoutDate
                    )
                    viewModel.updateUserProfile(updatedProfile)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(ViewModel())
    }
} 
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
                            Text(viewModel.userProfile?.name ?? "Unknown")
                                .font(.headline)
                            Text(viewModel.userProfile?.email ?? "Unknown")
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
                        Text("\(viewModel.userProfile?.level ?? 1)")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("XP")
                        Spacer()
                        Text("\(viewModel.userProfile?.xp ?? 0)")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Streak")
                        Spacer()
                        Text("\(viewModel.userProfile?.streakCount ?? 0) days")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Achievements")) {
                    ForEach(viewModel.userProfile?.achievements ?? []) { achievement in
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
                    .environmentObject(viewModel)
            }
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if let user = viewModel.userProfile {
                        let updatedProfile = UserProfile(
                            id: user.id,
                            name: name,
                            email: email,
                            level: user.level,
                            xp: user.xp,
                            streakCount: user.streakCount,
                            goals: user.goals,
                            achievements: user.achievements,
                            unlockedAchievements: user.unlockedAchievements,
                            lastWorkoutDate: user.lastWorkoutDate
                        )
                        viewModel.updateUserProfile(to: updatedProfile)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                if let user = viewModel.userProfile {
                    name = user.name
                    email = user.email
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(ViewModel())
    }
}


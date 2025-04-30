import SwiftUI
import FirebaseFirestore

struct UserProfile: Codable {
    var id: String
    var name: String
    var email: String
    var level: String
    var completedRoutines: [String]
    var achievements: [String]
}

class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    func fetchProfile() {
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            guard let data = snapshot?.data() else {
                // Create a new profile if none exists
                self?.createProfile(userId: userId)
                return
            }
            
            self?.profile = UserProfile(
                id: userId,
                name: data["name"] as? String ?? "",
                email: data["email"] as? String ?? "",
                level: data["level"] as? String ?? "Beginner",
                completedRoutines: data["completedRoutines"] as? [String] ?? [],
                achievements: data["achievements"] as? [String] ?? []
            )
        }
    }
    
    private func createProfile(userId: String) {
        let newProfile = UserProfile(
            id: userId,
            name: auth.currentUser?.displayName ?? "",
            email: auth.currentUser?.email ?? "",
            level: "Beginner",
            completedRoutines: [],
            achievements: []
        )
        
        db.collection("users").document(userId).setData([
            "name": newProfile.name,
            "email": newProfile.email,
            "level": newProfile.level,
            "completedRoutines": newProfile.completedRoutines,
            "achievements": newProfile.achievements
        ]) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.profile = newProfile
            }
        }
    }
    
    func updateProfile(name: String, level: String) {
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("users").document(userId).updateData([
            "name": name,
            "level": level
        ]) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.profile?.name = name
                self?.profile?.level = level
            }
        }
    }
}

struct UserProfileManagerView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var name = ""
    @State private var level = "Beginner"
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            List {
                if let profile = viewModel.profile {
                    Section(header: Text("Profile Information")) {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(profile.name)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(profile.email)
                        }
                        
                        HStack {
                            Text("Level")
                            Spacer()
                            Text(profile.level)
                        }
                    }
                    
                    Section(header: Text("Statistics")) {
                        HStack {
                            Text("Completed Routines")
                            Spacer()
                            Text("\(profile.completedRoutines.count)")
                        }
                        
                        HStack {
                            Text("Achievements")
                            Spacer()
                            Text("\(profile.achievements.count)")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(
                    name: $name,
                    level: $level,
                    onSave: {
                        viewModel.updateProfile(name: name, level: level)
                        showingEditProfile = false
                    }
                )
            }
            .onAppear {
                viewModel.fetchProfile()
                if let profile = viewModel.profile {
                    name = profile.name
                    level = profile.level
                }
            }
        }
    }
}

struct EditProfileView: View {
    @Binding var name: String
    @Binding var level: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    Picker("Level", selection: $level) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                }
            }
        }
    }
}

#Preview {
    UserProfileManagerView()
        .environmentObject(AuthManager())
} 
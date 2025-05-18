import SwiftUI

struct UserProfileManagerView: View {
    @Binding var profiles: [UserProfile]
    @Binding var selectedProfile: UserProfile?
    @State private var newName = ""
    @State private var newEmail = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var onSave: (() -> Void)?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Add New Profile")) {
                    TextField("Name", text: $newName)
                    TextField("Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button("Add Profile") {
                        addProfile()
                    }
                    .disabled(newName.isEmpty || newEmail.isEmpty)
                }
                
                Section(header: Text("Existing Profiles")) {
                    ForEach(profiles) { profile in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .font(.headline)
                                Text(profile.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if profile.id == selectedProfile?.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProfile = profile
                            onSave?()
                        }
                    }
                    .onDelete { indexSet in
                        deleteProfiles(at: indexSet)
                    }
                }
            }
            .navigationTitle("Manage Profiles")
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addProfile() {
        guard !newName.isEmpty && !newEmail.isEmpty else { return }
        
        // Validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: newEmail) {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }
        
        // Check if email already exists
        if profiles.contains(where: { $0.email.lowercased() == newEmail.lowercased() }) {
            alertMessage = "A profile with this email already exists"
            showingAlert = true
            return
        }
        
        let newProfile = UserProfile(
            id: UUID().uuidString,
            name: newName,
            email: newEmail,
            level: 1,
            xp: 0,
            streakCount: 0,
            lastActiveDate: Date(),
            achievements: [],
            unlockedRoutines: [],
            unlockedAchievements: []
        )
        
        profiles.append(newProfile)
        selectedProfile = newProfile
        newName = ""
        newEmail = ""
        onSave?()
    }
    
    private func deleteProfiles(at offsets: IndexSet) {
        // Don't allow deleting the last profile
        guard profiles.count > 1 else {
            alertMessage = "You must have at least one profile"
            showingAlert = true
            return
        }
        
        // If deleting the selected profile, select another one
        if let selected = selectedProfile,
           let index = profiles.firstIndex(where: { $0.id == selected.id }),
           offsets.contains(index) {
            // Select the first profile that's not being deleted
            if let newSelected = profiles.first(where: { !offsets.contains(profiles.firstIndex(of: $0)!) }) {
                selectedProfile = newSelected
            }
        }
        
        profiles.remove(atOffsets: offsets)
        onSave?()
    }
}

#if DEBUG
struct UserProfileManagerView_Previews: PreviewProvider {
    static var previews: some View {
        let profiles = [UserProfile(
            id: "1",
            name: "Test User",
            email: "test@example.com",
            level: 1,
            xp: 0,
            streakCount: 0,
            lastActiveDate: Date(),
            achievements: [],
            unlockedRoutines: [],
            unlockedAchievements: []
        )]
        let selectedProfile = profiles[0]
        
        return UserProfileManagerView(
            profiles: .constant(profiles),
            selectedProfile: .constant(selectedProfile)
        )
    }
}
#endif

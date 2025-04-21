import SwiftUI

struct UserProfileManagerView: View {
    @Binding var profiles: [UserProfile]
    @Binding var selectedProfile: UserProfile
    @Binding var allLogs: [UUID: [PoseLogEntry]]

    @State private var newName = ""
    @State private var editMode: EditMode = .inactive

    var onSave: (() -> Void)? = nil

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("New Profile Name", text: $newName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Add") {
                        let newProfile = UserProfile(
                            name: newName,
                            xp: 0,
                            level: 1,
                            streakCount: 0,
                            lastActiveDate: nil,
                            unlockedAchievements: [],
                            unlockedRoutines: [.standing]
                        )
                        profiles.append(newProfile)
                        selectedProfile = newProfile
                        newName = ""
                        saveProfiles()
                        onSave?()
                    }
                    .disabled(newName.isEmpty)
                }
                .padding()

                List {
                    ForEach(profiles) { profile in
                        HStack {
                            if editMode == .active {
                                TextField("Name", text: Binding(
                                    get: { profile.name },
                                    set: { newValue in
                                        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                                            profiles[index].name = newValue
                                            saveProfiles()
                                            onSave?()
                                        }
                                    }
                                ))
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.name)
                                        .fontWeight(.medium)

                                    Text("Level \(profile.level) · \(profile.xp % 100)/100 XP")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text("🔥 Streak: \(profile.streakCount) days")
                                        .font(.caption2)
                                        .foregroundColor(.orange)

                                    if !profile.unlockedAchievements.isEmpty {
                                        Text("🏆 \(profile.unlockedAchievements.count) Achievements")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }

                                    if profile.unlockedRoutines.count > 1 {
                                        Text("📖 Routines Unlocked: \(profile.unlockedRoutines.map { $0.displayName }.joined(separator: ", "))")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                            }

                            Spacer()
                            if profile == selectedProfile {
                                Text("✅")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProfile = profile
                            onSave?()
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let profile = profiles[index]
                            allLogs[profile.id] = nil
                            profiles.remove(at: index)
                            if profile.id == selectedProfile.id {
                                selectedProfile = profiles.first ?? UserProfile(name: "Default User")
                            }
                        }
                        saveProfiles()
                        saveLogs()
                        onSave?()
                    }
                }
                .environment(\.editMode, $editMode)
                .navigationTitle("Manage Profiles")
                .toolbar {
                    EditButton()
                }
            }
        }
    }

    func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            try? data.write(to: getProfilesFileURL())
        }
    }

    func saveLogs() {
        if let data = try? JSONEncoder().encode(allLogs) {
            try? data.write(to: getLogsFileURL())
        }
    }

    func getProfilesFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("UserProfiles.json")
    }

    func getLogsFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("UserLogs.json")
    }
}


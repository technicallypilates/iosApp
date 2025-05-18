import SwiftUI
import FirebaseAuth
import EventKit
import UserNotifications
import FirebaseAnalytics

struct ProfileView: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var authManager: AuthManager

    @State private var showingLogoutAlert = false
    @State private var showDeleteCredentialsPrompt = false
    @State private var deletePassword = ""
    @State private var deleteErrorMessage: String?
    @State private var showingProfileEditor = false
    @State private var profiles: [UserProfile] = []
    @State private var selectedProfile: UserProfile? = nil

    @State private var showingImagePicker = false
    @State private var selectedUIImage: UIImage?

    @State private var showingReminderAlert = false
    @State private var showingCalendarAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    @State private var showingCalendarSheet = false
    @State private var calendarEventDate = Date().addingTimeInterval(3600)
    @State private var calendarEventTitle = "Pilates Routine"
    @State private var calendarEventNotes = "Complete your Pilates workout routine."

    @State private var showingReminderSheet = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var reminderRepeats = true

    var body: some View {
        NavigationView {
            List {
                if let user = authManager.currentUser {
                    profileSection(user)
                    statsSection(user)
                    metricsSection(user)
                    performanceSection
                    achievementsSection(user)
                    leaderboardSection
                    communityChallengesSection
                    shareProgressSection
                    remindersSection
                    destructiveSection
                } else {
                    Text("No user is signed in.").foregroundColor(.gray)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingProfileEditor = true } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingProfileEditor) {
                UserProfileManagerView(profiles: $profiles, selectedProfile: $selectedProfile)
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedUIImage)
                    .onDisappear {
                        if let image = selectedUIImage,
                           let data = image.jpegData(compressionQuality: 0.8),
                           let currentUser = authManager.currentUser {
                            Task {
                                do {
                                    currentUser.profileImageData = data
                                    try await authManager.updateUserProfile(currentUser)
                                    viewModel.saveUsers()
                                } catch {
                                    print("Error updating profile image: \(error)")
                                }
                            }
                        }
                    }
            }
            .sheet(isPresented: $showingCalendarSheet) {
                VStack(spacing: 20) {
                    Text("Add Routine to Calendar").font(.headline)
                    DatePicker("Select Date & Time", selection: $calendarEventDate)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                    TextField("Event Title", text: $calendarEventTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    TextField("Notes", text: $calendarEventNotes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    Button("Add to Calendar") {
                        addRoutineToCalendar(date: calendarEventDate, title: calendarEventTitle, notes: calendarEventNotes)
                        showingCalendarSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Cancel") {
                        showingCalendarSheet = false
                    }
                    .foregroundColor(.red)
                }
                .padding()
            }
            .sheet(isPresented: $showingReminderSheet) {
                VStack(spacing: 20) {
                    Text("Schedule Daily Workout Reminder").font(.headline)
                    DatePicker("Select Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    Toggle("Repeat Daily", isOn: $reminderRepeats)
                        .padding(.horizontal)
                    Button("Set Reminder") {
                        scheduleWorkoutReminder(at: reminderTime, repeats: reminderRepeats)
                        showingReminderSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Cancel") {
                        showingReminderSheet = false
                    }
                    .foregroundColor(.red)
                }
                .padding()
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Log Out", role: .destructive) { try? authManager.signOut() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Error", isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteErrorMessage ?? "Unknown error")
            }
            .alert("Delete Account", isPresented: $showDeleteCredentialsPrompt) {
                Button("Delete", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {
                    showDeleteCredentialsPrompt = false
                    deletePassword = ""
                }
            } message: {
                VStack {
                    SecureField("Enter Password", text: $deletePassword)
                    Text("Please enter your password to confirm account deletion.")
                }
            }
            .alert(alertTitle, isPresented: $showingReminderAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert(alertTitle, isPresented: $showingCalendarAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Profile UI

    private func profileSection(_ user: UserProfile) -> some View {
        Section(header: Text("Profile")) {
            HStack {
                Button(action: { showingImagePicker = true }) {
                    if let data = user.profileImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
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
                VStack(alignment: .leading) {
                    Text(user.name).font(.headline)
                    Text(user.email).font(.subheadline).foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func statsSection(_ user: UserProfile) -> some View {
        Section(header: Text("Stats")) {
            LabeledContent("Level", value: "\(user.level)")
            LabeledContent("XP", value: "\(user.xp)")
            LabeledContent("Streak", value: "\(user.streakCount) days")
            LabeledContent("Avg Accuracy", value: "\(averageAccuracy)%")
        }
    }

    private func metricsSection(_ user: UserProfile) -> some View {
        Section(header: Text("Exercise Metrics")) {
            let metrics = user.calculateExerciseMetrics(from: viewModel.poseLog)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Accuracy")
                    Spacer()
                    Text("\(String(format: "%.1f", metrics.accuracy * 100))%")
                }
                ProgressView(value: metrics.accuracy)
                    .accentColor(.green)
                HStack {
                    Text("Consistency")
                    Spacer()
                    Text("\(String(format: "%.1f", metrics.consistency * 100))%")
                }
                ProgressView(value: metrics.consistency)
                    .accentColor(.orange)
                HStack {
                    Text("Best Streak")
                    Spacer()
                    Text("\(metrics.streak) days")
                }
                ProgressView(value: Double(metrics.streak) / 30.0) // Assume 30 as a max for visual
                    .accentColor(.blue)
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(Int(metrics.duration / 60)) min")
                }
                HStack {
                    Text("Difficulty")
                    Spacer()
                    Text("\(metrics.difficulty)")
                }
            }
            .font(.subheadline)
        }
    }

    private var performanceSection: some View {
        Section(header: Text("Performance")) {
            PerformanceChartView(logEntries: viewModel.poseLog, poses: viewModel.poses)
                .frame(height: 250)
        }
    }

    private func achievementsSection(_ user: UserProfile) -> some View {
        Section(header: Text("Achievements")) {
            if user.unlockedAchievements.isEmpty {
                Text("No achievements yet").foregroundColor(.gray)
            } else {
                ForEach(user.achievements.filter { user.unlockedAchievements.contains($0.id) }) { achievement in
                    HStack(alignment: .top) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        VStack(alignment: .leading) {
                            Text(achievement.name).font(.body)
                            Text(achievement.description).font(.caption).foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }

    private var leaderboardSection: some View {
        Section(header: Text("Leaderboard")) {
            ForEach(topUsersByXP, id: \.id) { user in
                HStack {
                    Text(user.name)
                    Spacer()
                    Text("XP: \(user.xp)").foregroundColor(.blue)
                }
            }
        }
    }

    private var communityChallengesSection: some View {
        Section(header: Text("Community Challenges")) {
            ForEach(viewModel.challenges) { challenge in
                VStack(alignment: .leading) {
                    Text(challenge.title).font(.headline)
                    Text(challenge.description).font(.caption).foregroundColor(.gray)
                }
            }
        }
    }

    private var shareProgressSection: some View {
        Section(header: Text("Share Progress")) {
            Button(action: shareProgress) {
                Label("Share My Progress", systemImage: "square.and.arrow.up")
            }
        }
    }

    private var remindersSection: some View {
        Section(header: Text("Reminders & Scheduling")) {
            Button(action: { showingReminderSheet = true }) {
                Label("Schedule Daily Workout Reminder", systemImage: "bell")
            }
            Button(action: { showingCalendarSheet = true }) {
                Label("Add Routine to Calendar", systemImage: "calendar")
            }
        }
    }

    private var destructiveSection: some View {
        Section {
            Button(role: .destructive) {
                showingLogoutAlert = true
            } label: {
                Label("Log Out", systemImage: "arrow.backward.circle.fill")
            }

            Button(role: .destructive) {
                showDeleteCredentialsPrompt = true
            } label: {
                Label("Delete Account", systemImage: "trash.circle.fill")
            }
        }
    }

    // MARK: - Helper Methods

    private func deleteAccount() async {
        do {
            try await authManager.deleteAccount(
                withEmail: authManager.currentUser?.email ?? "",
                password: deletePassword
            )
            showDeleteCredentialsPrompt = false
            deletePassword = ""
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }

    private var averageAccuracy: Int {
        guard !viewModel.poseLog.isEmpty else { return 0 }
        let totalAccuracy = viewModel.poseLog.reduce(0) { $0 + $1.accuracyScore }
        return Int((Double(totalAccuracy) / Double(viewModel.poseLog.count)).rounded())
    }

    private var topUsersByXP: [UserProfile] {
        viewModel.users.sorted { $0.xp > $1.xp }.prefix(5).map { $0 }
    }

    private func shareProgress() {}

    private func scheduleWorkoutReminder(at time: Date, repeats: Bool) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    let content = UNMutableNotificationContent()
                    content.title = "Time for Pilates!"
                    content.body = "Stay on track with your daily workout routine."
                    var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
                    let request = UNNotificationRequest(identifier: "dailyWorkoutReminder", content: content, trigger: trigger)
                    center.add(request) { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                alertTitle = "Error"
                                alertMessage = "Failed to schedule reminder: \(error.localizedDescription)"
                            } else {
                                alertTitle = "Success"
                                alertMessage = repeats ? "Daily workout reminder scheduled for \(String(format: "%02d:%02d", dateComponents.hour ?? 0, dateComponents.minute ?? 0)) (repeats daily)" : "Workout reminder scheduled for \(String(format: "%02d:%02d", dateComponents.hour ?? 0, dateComponents.minute ?? 0)) (one-time)"
                            }
                            showingReminderAlert = true
                        }
                    }
                } else {
                    alertTitle = "Permission Denied"
                    alertMessage = "Please enable notifications in Settings to schedule reminders"
                    showingReminderAlert = true
                }
            }
        }
    }

    private func addRoutineToCalendar(date: Date, title: String, notes: String) {
        let store = EKEventStore()
        store.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    let event = EKEvent(eventStore: store)
                    event.title = title
                    event.startDate = date
                    event.endDate = date.addingTimeInterval(1800) // 30 min duration
                    event.notes = notes
                    event.calendar = store.defaultCalendarForNewEvents
                    do {
                        try store.save(event, span: .thisEvent)
                        alertTitle = "Success"
                        alertMessage = "Routine added to calendar for \(event.startDate.formatted(date: .abbreviated, time: .shortened))"
                    } catch {
                        alertTitle = "Error"
                        alertMessage = "Failed to add to calendar: \(error.localizedDescription)"
                    }
                } else {
                    alertTitle = "Permission Denied"
                    alertMessage = "Please enable calendar access in Settings to add routines"
                }
                showingCalendarAlert = true
            }
        }
    }
}

// MARK: - ImagePicker Embedded Struct
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}


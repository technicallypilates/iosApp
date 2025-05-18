import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case passwordsDontMatch
    case invalidName
    case emailAlreadyInUse
    case invalidCredentials
    case networkError
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password must be at least 8 characters long and contain at least one number and one special character"
        case .passwordsDontMatch:
            return "Passwords do not match"
        case .invalidName:
            return "Name must be at least 2 characters long"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var error: Error?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                Task {
                    try? await self.fetchUserProfile(userId: user.uid)
                }
            } else {
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            try await fetchUserProfile(userId: result.user.uid)
        } catch {
            self.error = error
            throw error
        }
    }

    func signUp(email: String, password: String, name: String) async throws {
        try validateEmail(email)
        try validatePassword(password)
        try validateName(name)

        let result = try await auth.createUser(withEmail: email, password: password)
        let userProfile = UserProfile(
            id: result.user.uid,
            name: name,
            email: email
        )
        try await saveUserProfile(userProfile)

        DispatchQueue.main.async {
            self.currentUser = userProfile
            self.isAuthenticated = true
        }
    }

    func signOut() throws {
        try auth.signOut()
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    private func fetchUserProfile(userId: String) async throws {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data(),
              let profile = UserProfile(dictionary: data) else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }

        DispatchQueue.main.async {
            self.currentUser = profile
            self.isAuthenticated = true
        }
    }

    private func saveUserProfile(_ profile: UserProfile) async throws {
        guard let data = profile.dictionary else { return }
        try await db.collection("users").document(profile.id).setData(data)
    }

    func updateUserXP(_ amount: Int) async throws {
        guard var profile = currentUser else { return }
        profile.xp += amount
        profile.level = Int(sqrt(Double(profile.xp) / 100.0)) + 1
        try await saveUserProfile(profile)
        let updatedProfile = profile // Make a local copy for concurrency safety
        DispatchQueue.main.async {
            self.currentUser = updatedProfile
        }
    }

    func updatePoseAccuracy(poseId: UUID, routineId: UUID, accuracyScore: Int, repsCompleted: Int) async throws {
        guard let userId = currentUser?.id else { return }

        let entry = PoseLogEntry(
            poseId: poseId,
            routineId: routineId,
            repsCompleted: repsCompleted,
            accuracyScore: accuracyScore,
            timestamp: Date()
        )

        let data = entry.dictionary
        try await db.collection("users").document(userId)
            .collection("poseLogs")
            .document(entry.id.uuidString)
            .setData(data)
    }

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        try await saveUserProfile(profile)
        DispatchQueue.main.async {
            self.currentUser?.objectWillChange.send()
            self.currentUser = profile
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.invalidCredentials
        }
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
        try await user.reauthenticate(with: credential)
        try await user.updatePassword(to: newPassword)
    }

    func verifyEmail(_ email: String) async throws {
        try validateEmail(email)
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func deleteAccount(withEmail email: String, password: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.invalidCredentials
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
        try await user.delete()
        // Optionally, remove user data from Firestore
        try await db.collection("users").document(user.uid).delete()
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    // MARK: - Validation

    private func validateEmail(_ email: String) throws {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !predicate.evaluate(with: email) {
            throw AuthError.invalidEmail
        }
    }

    private func validatePassword(_ password: String) throws {
        let regex = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        if !predicate.evaluate(with: password) {
            throw AuthError.invalidPassword
        }
    }

    private func validateName(_ name: String) throws {
        if name.count < 2 {
            throw AuthError.invalidName
        }
    }
}


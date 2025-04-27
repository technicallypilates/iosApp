import Foundation
import Combine

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
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    
    private var users: [String: UserProfile] = [:] // In-memory user storage
    private var passwords: [String: String] = [:] // In-memory password storage (in real app, use secure storage)
    
    private init() {
        // Load authentication state on initialization
        loadAuthState()
        loadUsers()
    }
    
    // MARK: - Authentication State Management
    
    private func loadAuthState() {
        do {
            if DataManager.shared.fileExists(fileName: "authState.json") {
                let authState = try DataManager.shared.load(AuthState.self, from: "authState.json")
                isAuthenticated = authState.isAuthenticated
                
                if isAuthenticated {
                    currentUser = try DataManager.shared.load(UserProfile.self, from: "userProfile.json")
                }
            }
        } catch {
            print("Error loading auth state: \(error)")
        }
    }
    
    private func loadUsers() {
        do {
            if DataManager.shared.fileExists(fileName: "users.json") {
                users = try DataManager.shared.load([String: UserProfile].self, from: "users.json")
            }
            if DataManager.shared.fileExists(fileName: "passwords.json") {
                passwords = try DataManager.shared.load([String: String].self, from: "passwords.json")
            }
        } catch {
            print("Error loading users: \(error)")
        }
    }
    
    private func saveAuthState() {
        do {
            let authState = AuthState(isAuthenticated: isAuthenticated)
            try DataManager.shared.save(authState, to: "authState.json")
        } catch {
            print("Error saving auth state: \(error)")
        }
    }
    
    private func saveUsers() {
        do {
            try DataManager.shared.save(users, to: "users.json")
            try DataManager.shared.save(passwords, to: "passwords.json")
        } catch {
            print("Error saving users: \(error)")
        }
    }
    
    // MARK: - Validation Methods
    
    private func validateEmail(_ email: String) throws {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            throw AuthError.invalidEmail
        }
    }
    
    private func validatePassword(_ password: String) throws {
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$"
        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordRegex)
        if !passwordPredicate.evaluate(with: password) {
            throw AuthError.invalidPassword
        }
    }
    
    private func validateName(_ name: String) throws {
        if name.count < 2 {
            throw AuthError.invalidName
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws {
        try validateEmail(email)
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard let storedPassword = passwords[email],
              storedPassword == password,
              let user = users[email] else {
            throw AuthError.invalidCredentials
        }
        
        currentUser = UserProfile(
            name: "New User",
            email: email,
            xp: 0,
            level: 1,
            streakCount: 0,
            lastActiveDate: Date(),
            unlockedAchievements: [],
            unlockedRoutines: []
        )
        isAuthenticated = true
        saveAuthState()
        try DataManager.shared.save(user, to: "userProfile.json")
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        saveAuthState()
        
        // Clear user profile
        do {
            try DataManager.shared.delete(fileName: "userProfile.json")
        } catch {
            print("Error deleting user profile: \(error)")
        }
    }
    
    func signUp(name: String, email: String, password: String, confirmPassword: String) async throws {
        try validateName(name)
        try validateEmail(email)
        try validatePassword(password)
        
        if password != confirmPassword {
            throw AuthError.passwordsDontMatch
        }
        
        if users[email] != nil {
            throw AuthError.emailAlreadyInUse
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = UserProfile(
            id: UUID(),
            name: name,
            email: email,
            goals: ["Improve flexibility", "Build strength"],
            xp: 0,
            level: 1,
            streakCount: 0,
            lastActiveDate: Date(),
            unlockedAchievements: [],
            unlockedRoutines: []
        )
        
        users[email] = user
        passwords[email] = password
        saveUsers()
        
        currentUser = user
        isAuthenticated = true
        saveAuthState()
        try DataManager.shared.save(user, to: "userProfile.json")
    }
}

// MARK: - Supporting Types

private struct AuthState: Codable {
    let isAuthenticated: Bool
} 
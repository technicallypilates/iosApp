import Foundation
import Combine
import SwiftUI
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
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    
    private var users: [String: UserProfile] = [:] // In-memory user storage
    private var passwords: [String: String] = [:] // In-memory password storage (in real app, use secure storage)
    
    private let db = Firestore.firestore()
    
    private init() {
        // Check if user is already signed in
        if let user = Auth.auth().currentUser {
            loadUserProfile(userId: user.uid)
        }
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
    
    func signIn(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = result?.user.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                return
            }
            
            self?.loadUserProfile(userId: userId, completion: completion)
        }
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = result?.user.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                return
            }
            
            let initialGoals = [
                Goal(
                    title: "Improve flexibility",
                    description: "Complete 30 flexibility-focused exercises",
                    targetXP: 1000,
                    currentXP: 0
                ),
                Goal(
                    title: "Build strength",
                    description: "Complete 50 strength-focused exercises",
                    targetXP: 1500,
                    currentXP: 0
                )
            ]
            
            let user = UserProfile(
                id: UUID(uuidString: userId) ?? UUID(),
                name: name,
                email: email,
                level: 1,
                xp: 0,
                streakCount: 0,
                goals: initialGoals,
                achievements: [],
                unlockedAchievements: [],
                lastWorkoutDate: nil
            )
            
            self?.saveUserProfile(user) { result in
                switch result {
                case .success:
                    completion(.success(user))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func loadUserProfile(userId: String, completion: ((Result<UserProfile, Error>) -> Void)? = nil) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                completion?(.failure(error))
                return
            }
            
            guard let data = document?.data() else {
                completion?(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                return
            }
            
            // Parse the data and create a UserProfile
            let id = UUID(uuidString: userId) ?? UUID()
            let name = data["name"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let level = data["level"] as? Int ?? 1
            let xp = data["xp"] as? Int ?? 0
            let streakCount = data["streakCount"] as? Int ?? 0
            
            // Parse goals
            let goalsData = data["goals"] as? [[String: Any]] ?? []
            let goals = goalsData.compactMap { goalData -> Goal? in
                guard let title = goalData["title"] as? String,
                      let description = goalData["description"] as? String,
                      let targetXP = goalData["targetXP"] as? Int,
                      let currentXP = goalData["currentXP"] as? Int else {
                    return nil
                }
                return Goal(
                    title: title,
                    description: description,
                    targetXP: targetXP,
                    currentXP: currentXP
                )
            }
            
            // Parse achievements
            let achievementsData = data["achievements"] as? [[String: Any]] ?? []
            let achievements = achievementsData.compactMap { achievementData -> Achievement? in
                guard let name = achievementData["name"] as? String,
                      let description = achievementData["description"] as? String,
                      let isUnlocked = achievementData["isUnlocked"] as? Bool else {
                    return nil
                }
                return Achievement(name: name, description: description, isUnlocked: isUnlocked)
            }
            
            let lastWorkoutDate = (data["lastWorkoutDate"] as? Timestamp)?.dateValue()
            
            let user = UserProfile(
                id: id,
                name: name,
                email: email,
                level: level,
                xp: xp,
                streakCount: streakCount,
                goals: goals,
                achievements: achievements,
                unlockedAchievements: achievements.filter { $0.isUnlocked },
                lastWorkoutDate: lastWorkoutDate
            )
            
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = true
                completion?(.success(user))
            }
        }
    }
    
    private func saveUserProfile(_ user: UserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "name": user.name,
            "email": user.email,
            "level": user.level,
            "xp": user.xp,
            "streakCount": user.streakCount,
            "goals": user.goals.map { [
                "title": $0.title,
                "description": $0.description,
                "targetXP": $0.targetXP,
                "currentXP": $0.currentXP
            ] },
            "achievements": user.achievements.map { [
                "name": $0.name,
                "description": $0.description,
                "isUnlocked": $0.isUnlocked
            ] },
            "lastWorkoutDate": user.lastWorkoutDate.map { Timestamp(date: $0) } as Any
        ]
        
        db.collection("users").document(user.id.uuidString).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

private struct AuthState: Codable {
    let isAuthenticated: Bool
} 
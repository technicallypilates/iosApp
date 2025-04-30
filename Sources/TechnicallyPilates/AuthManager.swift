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
        case .invalidEmail: return "Please enter a valid email address"
        case .invalidPassword: return "Password must be at least 8 characters long and contain at least one number and one special character"
        case .passwordsDontMatch: return "Passwords do not match"
        case .invalidName: return "Name must be at least 2 characters long"
        case .emailAlreadyInUse: return "This email is already registered"
        case .invalidCredentials: return "Invalid email or password"
        case .networkError: return "Network error. Please check your connection"
        case .unknownError: return "An unknown error occurred"
        }
    }
}

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?

    private let db = Firestore.firestore()

    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.loadUserProfile(userId: user.uid)
            } else {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(self.mapFirebaseAuthError(error)))
                }
                return
            }

            guard let userId = result?.user.uid else {
                DispatchQueue.main.async {
                    completion(.failure(AuthError.unknownError))
                }
                return
            }

            self.loadUserProfile(userId: userId, completion: completion)
        }
    }

    func signUp(email: String, password: String, name: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(self.mapFirebaseAuthError(error)))
                }
                return
            }

            guard let user = result?.user else {
                DispatchQueue.main.async {
                    completion(.failure(AuthError.unknownError))
                }
                return
            }

            let userProfile = UserProfile(
                id: UUID(uuidString: user.uid) ?? UUID(),
                name: name,
                email: email,
                level: 1,
                xp: 0,
                streakCount: 0,
                goals: [],
                achievements: [],
                unlockedAchievements: [],
                lastWorkoutDate: nil
            )

            self.saveUserProfile(userProfile, userId: user.uid) { saveResult in
                switch saveResult {
                case .success:
                    // Let Firestore write settle before read
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.loadUserProfile(userId: user.uid, completion: completion)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    private func loadUserProfile(userId: String, completion: ((Result<UserProfile, Error>) -> Void)? = nil) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion?(.failure(self.mapFirebaseAuthError(error)))
                }
                return
            }

            guard let data = document?.data(), document?.exists == true else {
                if let user = Auth.auth().currentUser {
                    let fallbackUser = UserProfile(
                        id: UUID(uuidString: user.uid) ?? UUID(),
                        name: "User",
                        email: user.email ?? "",
                        level: 1,
                        xp: 0,
                        streakCount: 0,
                        goals: [],
                        achievements: [],
                        unlockedAchievements: [],
                        lastWorkoutDate: nil
                    )

                    self.saveUserProfile(fallbackUser, userId: user.uid) { result in
                        switch result {
                        case .success:
                            DispatchQueue.main.async {
                                self.currentUser = fallbackUser
                                self.isAuthenticated = true
                                completion?(.success(fallbackUser))
                            }
                        case .failure(let error):
                            DispatchQueue.main.async {
                                completion?(.failure(error))
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(.failure(AuthError.unknownError))
                    }
                }
                return
            }

            let user = UserProfile(
                id: UUID(uuidString: userId) ?? UUID(),
                name: data["name"] as? String ?? "",
                email: data["email"] as? String ?? "",
                level: data["level"] as? Int ?? 1,
                xp: data["xp"] as? Int ?? 0,
                streakCount: data["streakCount"] as? Int ?? 0,
                goals: [],
                achievements: [],
                unlockedAchievements: [],
                lastWorkoutDate: (data["lastWorkoutDate"] as? Timestamp)?.dateValue()
            )

            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = true
                completion?(.success(user))
            }
        }
    }

    private func saveUserProfile(_ user: UserProfile, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "name": user.name,
            "email": user.email,
            "level": user.level,
            "xp": user.xp,
            "streakCount": user.streakCount,
            "lastWorkoutDate": user.lastWorkoutDate.map { Timestamp(date: $0) } as Any
        ]

        db.collection("users").document(userId).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func mapFirebaseAuthError(_ error: Error) -> AuthError {
        let code = (error as NSError).code
        switch AuthErrorCode.Code(rawValue: code) {
        case .emailAlreadyInUse: return .emailAlreadyInUse
        case .invalidEmail: return .invalidEmail
        case .weakPassword: return .invalidPassword
        case .wrongPassword, .userNotFound: return .invalidCredentials
        case .networkError: return .networkError
        default: return .unknownError
        }
    }
}


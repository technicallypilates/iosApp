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
            DispatchQueue.main.async {
                if let user = user {
                    self?.loadUserProfile(userId: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(self?.mapFirebaseAuthError(error) ?? AuthError.unknownError))
                return
            }

            guard let userId = result?.user.uid else {
                completion(.failure(AuthError.unknownError))
                return
            }

            self?.loadUserProfile(userId: userId, completion: completion)
        }
    }

    func signUp(email: String, password: String, name: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(self?.mapFirebaseAuthError(error) ?? AuthError.unknownError))
                return
            }

            guard let userId = result?.user.uid else {
                completion(.failure(AuthError.unknownError))
                return
            }

            let user = UserProfile(
                id: UUID(),
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

            self?.saveUserProfile(user, userId: userId) { result in
                switch result {
                case .success:
                    completion(.success(user))
                case .failure(let error):
                    completion(.failure(error))
                }
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

    private func loadUserProfile(userId: String, completion: ((Result<UserProfile, Error>) -> Void)? = nil) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                completion?(.failure(self?.mapFirebaseAuthError(error) ?? AuthError.unknownError))
                return
            }

            guard let data = document?.data() else {
                completion?(.failure(AuthError.unknownError))
                return
            }

            let user = UserProfile(
                id: UUID(),
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
                self?.currentUser = user
                self?.isAuthenticated = true
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


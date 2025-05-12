import Foundation
import UIKit
import FirebaseFirestore

class SocialManager {
    static let shared = SocialManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Social Features
    
    struct SocialProfile: Codable {
        let userId: String
        let username: String
        let level: Int
        let xp: Int
        let achievements: [Achievement]
        let routinesCompleted: Int
        let streakCount: Int
        let isPublic: Bool
    }

    // MARK: - UserProgress model (used for sharing)
    struct UserProgress: Codable {
        let level: Int
        let xp: Int
        let streakCount: Int
        let routinesCompleted: Int
    }
    
    // MARK: - Profile Management
    
    func updateSocialProfile(_ profile: SocialProfile) async throws {
        try await db.collection("social_profiles").document(profile.userId).setData(from: profile)
    }
    
    func getSocialProfile(userId: String) async throws -> SocialProfile {
        let document = try await db.collection("social_profiles").document(userId).getDocument()
        return try document.data(as: SocialProfile.self)
    }
    
    // MARK: - Achievements Sharing
    
    func shareAchievement(_ achievement: Achievement) -> UIActivityViewController {
        let text = "I just unlocked the \(achievement.name) achievement in TechnicallyPilates! 🎉"
        return UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    
    // MARK: - Progress Sharing
    
    func shareProgress(_ progress: UserProgress) -> UIActivityViewController {
        let text = """
        My TechnicallyPilates Progress:
        Level: \(progress.level)
        XP: \(progress.xp)
        Streak: \(progress.streakCount) days
        Routines Completed: \(progress.routinesCompleted)
        """
        return UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    
    // MARK: - Social Feed
    
    struct SocialPost: Codable, Identifiable {
        let id: String
        let userId: String
        let username: String
        let type: PostType
        let content: String
        let timestamp: Date
        var likes: Int
        var comments: [Comment]
        
        enum PostType: String, Codable {
            case achievement
            case milestone
            case routine
        }
    }
    
    struct Comment: Codable, Identifiable {
        let id: String
        let userId: String
        let username: String
        let content: String
        let timestamp: Date
    }
    
    func createPost(_ post: SocialPost) async throws {
        try await db.collection("social_posts").document(post.id).setData(from: post)
    }
    
    func getFeed(limit: Int = 20) async throws -> [SocialPost] {
        let snapshot = try await db.collection("social_posts")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: SocialPost.self) }
    }
    
    // MARK: - Social Interactions
    
    func likePost(_ postId: String) async throws {
        try await db.collection("social_posts").document(postId).updateData([
            "likes": FieldValue.increment(Int64(1))
        ])
    }
    
    func addComment(_ comment: Comment, to postId: String) async throws {
        try await db.collection("social_posts").document(postId).updateData([
            "comments": FieldValue.arrayUnion([comment])
        ])
    }
    
    // MARK: - Friend System
    
    struct FriendRequest: Codable {
        let id: String
        let fromUserId: String
        let toUserId: String
        let status: RequestStatus
        let timestamp: Date
        
        enum RequestStatus: String, Codable {
            case pending
            case accepted
            case rejected
        }
    }
    
    func sendFriendRequest(to userId: String) async throws {
        let request = FriendRequest(
            id: UUID().uuidString,
            fromUserId: AuthManager.shared.currentUser?.id ?? "",
            toUserId: userId,
            status: .pending,
            timestamp: Date()
        )
        
        try await db.collection("friend_requests").document(request.id).setData(from: request)
    }
    
    func acceptFriendRequest(_ requestId: String) async throws {
        try await db.collection("friend_requests").document(requestId).updateData([
            "status": FriendRequest.RequestStatus.accepted.rawValue
        ])
    }
    
    // MARK: - Privacy Settings
    
    func updatePrivacySettings(isPublic: Bool) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        try await db.collection("social_profiles").document(userId).updateData([
            "isPublic": isPublic
        ])
    }
}


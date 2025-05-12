import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Event Tracking
    
    func trackEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
    
    func trackUserProgress(_ profile: UserProfile) {
        let parameters: [String: Any] = [
            "level": profile.level,
            "xp": profile.xp,
            "streak_count": profile.streakCount,
            "routines_completed": profile.unlockedRoutines.count,
            "total_workout_time": 0 // Add if you track this
        ]
        trackEvent("user_progress", parameters: parameters)
    }
    
    func trackRoutineCompletion(_ routine: Routine, accuracy: Double) {
        let parameters: [String: Any] = [
            "routine_id": routine.id.uuidString,
            "routine_name": routine.name,
            "accuracy": accuracy,
            "xp_earned": routine.xpReward
        ]
        trackEvent("routine_completed", parameters: parameters)
    }
    
    func trackPoseAttempt(_ pose: Pose, accuracy: Double) {
        let parameters: [String: Any] = [
            "pose_id": pose.id.uuidString,
            "pose_name": pose.name,
            "accuracy": accuracy
        ]
        trackEvent("pose_attempt", parameters: parameters)
    }
    
    func trackAchievementUnlocked(_ achievement: Achievement) {
        let parameters: [String: Any] = [
            "achievement_id": achievement.id.uuidString,
            "achievement_name": achievement.name
        ]
        trackEvent("achievement_unlocked", parameters: parameters)
    }
    
    // MARK: - User Properties
    
    func setUserProperties(_ profile: UserProfile) {
        Analytics.setUserID(profile.id)
        Analytics.setUserProperty(String(profile.level), forName: "user_level")
        Analytics.setUserProperty(String(profile.xp), forName: "user_xp")
        Analytics.setUserProperty(String(profile.streakCount), forName: "streak_count")
    }
    
    // MARK: - Error Tracking
    
    func trackError(_ error: Error, context: String) {
        let parameters: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_context": context
        ]
        trackEvent("error_occurred", parameters: parameters)
    }
    
    // MARK: - Session Tracking
    
    func trackSessionStart() {
        trackEvent("session_start")
    }
    
    func trackSessionEnd(duration: TimeInterval) {
        let parameters: [String: Any] = [
            "session_duration": duration
        ]
        trackEvent("session_end", parameters: parameters)
    }
} 
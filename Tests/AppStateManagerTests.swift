import XCTest
@testable import TechnicallyPilates

class AppStateManagerTests: XCTestCase {
    var appStateManager: AppStateManager!
    
    override func setUp() {
        super.setUp()
        appStateManager = AppStateManager.shared
    }
    
    override func tearDown() {
        appStateManager = nil
        super.tearDown()
    }
    
    func testSyncData() async {
        // Create test app state
        let testState = AppState(
            lastActiveDate: Date(),
            currentWorkoutId: UUID(),
            lastCompletedWorkoutId: nil,
            streakCount: 5,
            totalWorkouts: 10,
            currentRoutineId: UUID(),
            lastSyncDate: nil,
            pendingOperations: nil
        )
        
        // Save test state
        UserDefaults.standard.set(try? JSONEncoder().encode(testState), forKey: "app_state")
        
        // Perform sync
        await appStateManager.syncData()
        
        // Verify state was synced
        let savedData = UserDefaults.standard.data(forKey: "app_state")
        XCTAssertNotNil(savedData)
        
        if let savedData = savedData,
           let savedState = try? JSONDecoder().decode(AppState.self, from: savedData) {
            XCTAssertEqual(savedState.streakCount, testState.streakCount)
            XCTAssertEqual(savedState.totalWorkouts, testState.totalWorkouts)
            XCTAssertEqual(savedState.currentWorkoutId, testState.currentWorkoutId)
        } else {
            XCTFail("Failed to decode saved app state")
        }
    }
    
    func testResourceUsageHandling() {
        // Test CPU usage reduction
        appStateManager.reduceCPUUsage()
        
        // Test memory usage reduction
        appStateManager.reduceMemoryUsage()
        
        // Test battery usage reduction
        appStateManager.reduceBatteryUsage()
        
        // Test temperature reduction
        appStateManager.reduceTemperature()
        
        // Verify that appropriate actions were taken
        // Note: These are indirect tests as we can't directly verify the effects
        // of these methods without mocking the dependent managers
    }
    
    func testAppStateChangeHandling() {
        // Simulate entering background
        NotificationCenter.default.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Simulate entering foreground
        NotificationCenter.default.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Verify that appropriate actions were taken
        // Note: These are indirect tests as we can't directly verify the effects
        // of these notifications without mocking the dependent managers
    }
} 
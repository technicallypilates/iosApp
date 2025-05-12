import XCTest
@testable import TechnicallyPilates

class UserDefaultsManagerTests: XCTestCase {
    var userDefaultsManager: UserDefaultsManager!
    let testKey = "test_key"
    let testValue = "test_value"
    
    override func setUp() {
        super.setUp()
        userDefaultsManager = UserDefaultsManager.shared
        // Clear any existing test data
        UserDefaults.standard.removeObject(forKey: testKey)
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        userDefaultsManager = nil
        super.tearDown()
    }
    
    func testSetAndGetUserPreference() {
        // Set preference
        userDefaultsManager.setUserPreference(testValue, forKey: testKey)
        
        // Get preference
        let retrievedValue: String = userDefaultsManager.getUserPreference(forKey: testKey, defaultValue: "")
        
        // Verify
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    func testRemoveUserPreference() {
        // Set preference
        userDefaultsManager.setUserPreference(testValue, forKey: testKey)
        
        // Remove preference
        userDefaultsManager.removeUserPreference(forKey: testKey)
        
        // Verify
        let retrievedValue: String? = userDefaultsManager.getUserPreference(forKey: testKey, defaultValue: nil)
        XCTAssertNil(retrievedValue)
    }
    
    func testMigrateData() async {
        let oldKey = "old_key"
        let newKey = "new_key"
        let testValue = "test_value"
        
        // Set old value
        UserDefaults.standard.set(testValue, forKey: oldKey)
        
        // Perform migration
        await userDefaultsManager.migrateData(from: oldKey, to: newKey)
        
        // Verify
        XCTAssertNil(UserDefaults.standard.object(forKey: oldKey))
        XCTAssertEqual(UserDefaults.standard.string(forKey: newKey), testValue)
    }
    
    func testBatchOperations() async {
        let updates = [
            ("key1", "value1"),
            ("key2", "value2"),
            ("key3", "value3")
        ]
        
        // Perform batch update
        await userDefaultsManager.batchUpdate(updates)
        
        // Verify
        for (key, value) in updates {
            let retrievedValue: String = userDefaultsManager.getUserPreference(forKey: key, defaultValue: "")
            XCTAssertEqual(retrievedValue, value)
        }
        
        // Test batch delete
        await userDefaultsManager.batchDelete(updates.map { $0.0 })
        
        // Verify
        for (key, _) in updates {
            let retrievedValue: String? = userDefaultsManager.getUserPreference(forKey: key, defaultValue: nil)
            XCTAssertNil(retrievedValue)
        }
    }
    
    func testDataValidation() {
        // Test valid data
        userDefaultsManager.setUserPreference(testValue, forKey: testKey)
        XCTAssertTrue(userDefaultsManager.validateData(forKey: testKey))
        
        // Test invalid data
        XCTAssertFalse(userDefaultsManager.validateData(forKey: "non_existent_key"))
        
        // Test data structure validation
        let testSettings = UserSettings(
            notificationsEnabled: true,
            soundEnabled: true,
            darkModeEnabled: false,
            autoPlayEnabled: true,
            language: "en",
            measurementSystem: "metric"
        )
        
        userDefaultsManager.setUserSettings(testSettings)
        XCTAssertTrue(userDefaultsManager.validateDataStructure(forKey: "user_settings", type: UserSettings.self))
    }
} 
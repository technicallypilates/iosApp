import Foundation
import LocalAuthentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    private let context = LAContext()
    private var error: NSError?
    
    private init() {}
    
    // MARK: - Biometric Type
    
    enum BiometricType {
        case none
        case touchID
        case faceID
        case unknown
    }
    
    var biometricType: BiometricType {
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        @unknown default:
            return .unknown
        }
    }
    
    // MARK: - Authentication
    
    func authenticate(reason: String = "Authenticate to access your account") async throws -> Bool {
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw error ?? NSError(domain: "BiometricAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Biometric authentication not available"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    // MARK: - Keychain Integration
    
    func saveToKeychain(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "BiometricAuth", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save to keychain"])
        }
    }
    
    func loadFromKeychain(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw NSError(domain: "BiometricAuth", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to load from keychain"])
        }
        
        return data
    }
    
    // MARK: - Secure Storage
    
    func saveSecureData(_ data: Data, forKey key: String) throws {
        try saveToKeychain(key: key, data: data)
    }
    
    func loadSecureData(forKey key: String) throws -> Data {
        return try loadFromKeychain(key: key)
    }
    
    // MARK: - Biometric Status
    
    var isBiometricAvailable: Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var biometricTypeDescription: String {
        switch biometricType {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .unknown:
            return "Unknown"
        }
    }
} 
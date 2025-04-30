//
//  TechnicallyPilatesApp.swift
//  TechnicallyPilates
//
//  Created by Patrick O'Rourke on 22/03/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct TechnicallyPilatesApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    init() {
        setupFirebase()
    }
    
    private func setupFirebase() {
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            fatalError("Couldn't load Firebase configuration file.")
        }
        
        FirebaseApp.configure(options: options)
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

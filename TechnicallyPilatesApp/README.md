# TechnicallyPilates

A SwiftUI-based iOS app for Pilates training with pose detection and real-time feedback.

## Setup Instructions

1. Clone the repository
2. Open the project in Xcode
3. Add your `GoogleService-Info.plist` file:
   - Download it from the Firebase Console
   - Drag it into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Select your target in "Add to targets"

4. Install dependencies:
   - Open Xcode
   - Go to File > Add Packages
   - Add Firebase iOS SDK: https://github.com/firebase/firebase-ios-sdk.git
   - Select these products:
     - FirebaseAnalytics
     - FirebaseAuth
     - FirebaseFirestore

5. Build and run the project

## Features

- User authentication
- Pilates routine management
- Real-time pose detection
- Progress tracking
- User profile management

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Architecture

The app follows MVVM architecture with the following structure:

- Views: SwiftUI views
- Models: Data models and structures
- ViewModels: Business logic and state management
- Managers: Service layer for Firebase and other external services
- Camera: Camera and pose detection functionality 
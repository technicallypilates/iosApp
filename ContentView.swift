import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewModel = ViewModel()
    
    @State private var currentPoseIndex: Int = 0

    @State private var userProfile = UserProfile(
        id: UUID().uuidString,
        name: "User1",
        email: "user1@example.com",
        level: 1,
        xp: 0,
        streakCount: 0,
        lastActiveDate: Date(),
        achievements: [],
        unlockedRoutines: [],
        unlockedAchievements: []
    )

    @State private var pickerVisible = true
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                    
                    RoutinesView()
                        .tabItem {
                            Label("Routines", systemImage: "list.bullet")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person")
                        }
                }
                .environmentObject(viewModel)
            } else {
                LoginView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

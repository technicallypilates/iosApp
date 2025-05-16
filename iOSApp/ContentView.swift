import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewModel = ViewModel()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authManager.isAuthenticated, let user = authManager.currentUser {
                contentView(user: user)
            } else {
                LoginView()
            }
        }
        .task {
            if authManager.isAuthenticated, let user = authManager.currentUser {
                viewModel.onLogin(user: user)
            }
        }
    }

    @ViewBuilder
    private func contentView(user: UserProfile) -> some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Camera", systemImage: "camera")
                }
                .tag(0)

            RoutinesView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Routines", systemImage: "list.bullet")
                }
                .tag(1)

            ProfileView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(2)
        }
    }
}


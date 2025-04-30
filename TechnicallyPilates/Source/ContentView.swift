import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var selectedTab = 0
    @State private var isShowingLogin = false
    
    var body: some View {
        Group {
            if viewModel.isAuthenticated {
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
            } else {
                AuthView()
                    .environmentObject(viewModel)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct AuthView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                    
                    if isSignUp {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                    }
                }
                
                Section {
                    Button(isSignUp ? "Sign Up" : "Sign In") {
                        if isSignUp {
                            viewModel.signUp(email: email, password: password, name: name)
                        } else {
                            viewModel.signIn(email: email, password: password)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))
                }
                
                Section {
                    Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                        isSignUp.toggle()
                    }
                }
            }
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 

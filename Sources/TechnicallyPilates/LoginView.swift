import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var viewModel: ViewModel? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            if authManager.isAuthenticated {
                Group {
                    if let vm = viewModel {
                        HomeView()
                            .environmentObject(vm)
                    } else {
                        ProgressView("Loading...")
                    }
                }
                .onAppear {
                    if viewModel == nil, let user = authManager.currentUser {
                        DispatchQueue.main.async {
                            let newVM = ViewModel()
                            newVM.onLogin(user: user)
                            viewModel = newVM
                        }
                    }
                }

            } else {
                VStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            Image(systemName: "figure.pilates")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)

                            Text("Technically Pilates")
                                .font(.largeTitle).bold()

                            if isSignUp {
                                TextField("Name", text: $name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.words)
                            }

                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)

                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            if isSignUp {
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            Button(action: handleAuthentication) {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Text(isSignUp ? "Sign Up" : "Sign In")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .disabled(isLoading)

                            Button(action: toggleAuthMode) {
                                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar) // <-- this replaces .navigationBarHidden(true)
            }
        }
    }

    // MARK: - Auth Handling
    private func handleAuthentication() {
        isLoading = true
        errorMessage = nil

        if isSignUp {
            guard validateSignUpFields() else {
                isLoading = false
                return
            }

            authManager.signUp(email: email, password: password, name: name) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    handleAuthResult(result)
                }
            }
        } else {
            authManager.signIn(email: email, password: password) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    handleAuthResult(result)
                }
            }
        }
    }

    private func handleAuthResult(_ result: Result<UserProfile, Error>) {
        if case .failure(let error) = result {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleAuthMode() {
        withAnimation {
            isSignUp.toggle()
            errorMessage = nil
            confirmPassword = ""
        }
    }

    private func validateSignUpFields() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).count < 2 {
            errorMessage = AuthError.invalidName.localizedDescription
            return false
        }
        if !email.contains("@") || !email.contains(".") {
            errorMessage = AuthError.invalidEmail.localizedDescription
            return false
        }
        if password.count < 8 {
            errorMessage = AuthError.invalidPassword.localizedDescription
            return false
        }
        if password != confirmPassword {
            errorMessage = AuthError.passwordsDontMatch.localizedDescription
            return false
        }
        return true
    }
}


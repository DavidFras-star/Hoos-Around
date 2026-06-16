import SwiftUI
import FirebaseAuth

struct CreatePasswordView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToDOB = false

    private var email: String {
        onboardingVM.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Create a password")
                .font(.title)
                .bold()
                .foregroundColor(.white)

            SecureField("Password", text: $password)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)

            SecureField("Confirm password", text: $confirmPassword)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)

            if isSaving {
                ProgressView()
            } else {
                Button("Continue") {
                    handleSavePassword()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(password.isEmpty || password != confirmPassword)
            }

            Spacer()

            NavigationLink(
                "",
                destination: EnterDOBView().environmentObject(onboardingVM),
                isActive: $navigateToDOB
            )
            .opacity(0)
        }
        .padding()
        .background(LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func handleSavePassword() {
        guard password == confirmPassword else {
            alertMessage = "Passwords don’t match."
            showAlert = true
            return
        }

        isSaving = true

        // Create and sign in the verified user (createUser signs in automatically on success)
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isSaving = false
            if let error = error {
                alertMessage = "Failed to create account: \(error.localizedDescription)"
                showAlert = true
                return
            }

            guard let user = result?.user else {
                alertMessage = "Failed to create account. Please try again."
                showAlert = true
                return
            }

            print("✅ Created new Firebase user:", user.uid)

            // No need (and not allowed) to assign onboardingVM.userId — it's computed.
            // If you have a listener: onboardingVM.startUserListener()

            navigateToDOB = true
        }
    }
}

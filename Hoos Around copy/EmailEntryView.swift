import SwiftUI
import FirebaseFunctions
import FirebaseAuth

struct EmailEntryView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToWaiting = false
    @State private var isLoading = false

    // Gen-2 callable client in us-central1
    private let functions = Functions.functions(region: "us-central1")

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Enter your .edu email")
                .font(.title)
                .bold()
                .foregroundColor(.white)

            Text("We’ll use this to confirm you’re part of your university.")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("University email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)

            if isLoading {
                ProgressView()
            } else {
                Button(action: handleContinue) {
                    Text("Continue")
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isValidEduEmail(email) ? Color.white : Color.white.opacity(0.5))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(!isValidEduEmail(email))
            }

            Spacer()

            NavigationLink(
                "",
                destination: CodeVerificationView(email: email).environmentObject(onboardingVM),
                isActive: $navigateToWaiting
            )
            .opacity(0)
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.purple.opacity(0.95), Color.black],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Oops"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func isValidEduEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.edu$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func handleContinue() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard isValidEduEmail(trimmed) else {
            alertMessage = "Please enter a valid .edu email."
            showAlert = true
            return
        }

        isLoading = true
        let callable = functions.httpsCallable("sendVerificationCode")

        callable.call(["email": trimmed]) { result, error in
            isLoading = false

            if let error = error as NSError? {
                let details = (error.userInfo[FunctionsErrorDetailsKey] as? String) ?? "no details"
                print("sendVerificationCode error:", error.domain, error.code, details)

                switch error.code {
                case 7:
                    alertMessage = "We couldn’t reach the verification service. Try again, and if this persists, please update the app or contact support."
                default:
                    alertMessage = "Failed to send code: \(details)"
                }
                showAlert = true
                return
            }

            // ✅ Success: remember the verified email for later steps
            self.onboardingVM.email = trimmed
            self.email = trimmed

            // Move to code entry screen
            navigateToWaiting = true
        }
    }
}


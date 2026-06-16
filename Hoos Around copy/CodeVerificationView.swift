import SwiftUI
import FirebaseFunctions

struct CodeVerificationView: View {
    let email: String
    
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var code: String = ""
    @State private var isVerifying = false
    @State private var navigateToPassword = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Explicit region for Gen-2 callables
    private let functions = Functions.functions(region: "us-central1")

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Enter Your Code")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)

                Text("We emailed a 6-digit code to \(email).\nEnter it below to verify your email.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal)

                TextField("6-digit code", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode) // iOS auto-fill
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                Button(action: verifyCode) {
                    if isVerifying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Verify Code")
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                }
                .disabled(isVerifying || code.count != 6)
                .padding(.horizontal)

                NavigationLink(
                    "",
                    destination: CreatePasswordView().environmentObject(onboardingVM),
                    isActive: $navigateToPassword
                )
                .opacity(0)

                Spacer()
            }
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Verification Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func verifyCode() {
        isVerifying = true

        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanedCode  = code.trimmingCharacters(in: .whitespacesAndNewlines)

        let data: [String: Any] = ["email": cleanedEmail, "code": cleanedCode]
        let callable = functions.httpsCallable("verifyCode")

        callable.call(data) { result, error in
            isVerifying = false

            if let ns = error as NSError? {
                // Prefer server-provided details (from HttpsError third param)
                let details = (ns.userInfo[FunctionsErrorDetailsKey] as? String) ?? ns.localizedDescription
                self.errorMessage = details
                self.showError = true
                return
            }

            // Success → proceed to password creation
            navigateToPassword = true
        }
    }
}


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoggingIn = false
    @State private var navigateToHome = false  // Added this to trigger the navigation
    @State private var showPassword = false    // show/hide toggle
    
    // NEW: navigate to onboarding for new users
    @State private var navigateToOnboarding = false
    
    var body: some View {
        ZStack {
            // Root gradient behind everything (fills safe areas)
            LinearGradient(colors: [Color.purple, Color.black],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Text("Log In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text("Please enter your .edu email and password to log in.")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                // Password with show/hide eye
                ZStack {
                    if showPassword {
                        TextField("Password", text: $password)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .foregroundColor(.black)       // ← password text is black
                            .padding(.trailing, 44)        // room for eye
                    } else {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .foregroundColor(.black)       // ← password text is black
                            .padding(.trailing, 44)        // room for eye
                    }
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .overlay(alignment: .trailing) {
                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.white.opacity(0.9))   // ~90% white
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)            // 44×44 tap target
                    }
                    .contentShape(Rectangle())
                    .padding(.trailing, 6)                          // slight inset
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 8)
                }
                
                if isLoggingIn {
                    ProgressView()
                } else {
                    Button(action: login) {
                        Text("Log In")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(email.isEmpty || password.isEmpty)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity) // fill screen
            
            // Hidden NavigationLink to HomeView (inside ZStack so gradient covers it)
            NavigationLink(
                "",
                destination: TabBarView().environmentObject(onboardingVM),
                isActive: $navigateToHome
            )
            .opacity(0)
            
            // NEW: Hidden NavigationLink to the start of onboarding
            NavigationLink(
                "",
                destination: IntroToQuizView().environmentObject(onboardingVM),
                isActive: $navigateToOnboarding
            )
            .opacity(0)
        }
    }
    
    func login() {
        isLoggingIn = true
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoggingIn = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    // Decide where to go based on onboardingComplete
                    let uid = result?.user.uid ?? Auth.auth().currentUser?.uid
                    guard let uid else {
                        errorMessage = "Missing user ID."
                        return
                    }
                    Firestore.firestore().collection("users").document(uid).getDocument { snap, _ in
                        let complete = (snap?.data()?["onboardingComplete"] as? Bool) ?? false
                        if complete {
                            // ✅ IMPORTANT: set VM gate so TabBar doesn't show the auth cover
                            onboardingVM.onboardingComplete = true
                            // (Optional) prefetch basics so tabs have data immediately
                            onboardingVM.loadFromFirestore(uid: uid)
                            navigateToHome = true
                        } else {
                            // Ensure a fresh onboarding session for a new/incomplete user
                            onboardingVM.stopUserListener()
                            onboardingVM.resetAll()
                            navigateToOnboarding = true
                        }
                    }
                }
            }
        }
    }
}

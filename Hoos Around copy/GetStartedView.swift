import SwiftUI

struct GetStartedView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var navigateToEmailEntry = false
    @State private var navigateToLogin = false  // Added this to handle navigation to LoginView

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.purple.opacity(0.9), Color.black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Text("Hoos Around")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Your campus. Your people. Found faster.")
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    // DEV ONLY: Always show the main HomeView, no campus restriction!
                        // ... rest of your HomeView goes here ...

                    Button(action: {
                        onboardingVM.resetAll()          // this calls stopUserListener() inside
                        navigateToEmailEntry = true
                    }) {
                        Text("Get Started")
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .disabled(locationManager.isWithinCampusRadius == false)

                    Button(action: {
                        navigateToLogin = true  // Navigate to LoginView
                    }) {
                        Text("Log In")
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    NavigationLink(
                        "",
                        destination: EmailEntryView().environmentObject(onboardingVM),
                        isActive: $navigateToEmailEntry
                    )
                    .opacity(0)

                    // Hidden NavigationLink to LoginView
                    NavigationLink(
                        "",
                        destination: LoginView().environmentObject(onboardingVM),
                        isActive: $navigateToLogin
                    )
                    .opacity(0)
                }
                .padding()
            }
        }
    }
}


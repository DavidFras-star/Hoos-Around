import SwiftUI

struct ConfirmAgeView: View {
    let birthdate: Date
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var navigateToName = false

    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: now)
        return ageComponents.year ?? 0
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("You’re \(age)")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)

            Text("Does that look right?")
                .foregroundColor(.white.opacity(0.85))

            Button("Yes, continue") {
                navigateToName = true
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .padding(.horizontal)

            Button("Go back") {
                // Navigation handled by stack pop
                // Will be used with NavigationStack (automatically works)
            }
            .foregroundColor(.white.opacity(0.7))

            Spacer()

            NavigationLink(
                "",
                destination: EnterNameView().environmentObject(onboardingVM),
                isActive: $navigateToName
            )
            .opacity(0)

        }
        .padding()
        .background(LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}


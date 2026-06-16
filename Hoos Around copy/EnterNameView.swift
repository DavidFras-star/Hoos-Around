import SwiftUI

struct EnterNameView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var navigateToIntroQuiz = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("What’s your name?")
                .font(.title)
                .bold()
                .foregroundColor(.white)

            TextField("First name", text: $firstName)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)

            TextField("Last name", text: $lastName)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)

            Button("Continue") {
                onboardingVM.firstName = firstName
                onboardingVM.lastName = lastName
                navigateToIntroQuiz = true
            
            }
            .disabled(firstName.isEmpty || lastName.isEmpty)
            .padding()
            .frame(maxWidth: .infinity)
            .background(firstName.isEmpty || lastName.isEmpty ? Color.gray : Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            NavigationLink(
                "",
                destination: IntroToQuizView().environmentObject(onboardingVM),
                isActive: $navigateToIntroQuiz
            )
            .opacity(0)

        }
        .padding()
        .background(LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}


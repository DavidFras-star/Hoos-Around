import SwiftUI

struct IntroToQuizView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var navigateToCards = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Let’s get a sense of your vibe.")
                .font(.title)
                .bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("This will help us show you people you’d naturally click with.")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Let’s Go") {
                navigateToCards = true
            }

            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .padding(.horizontal)

            NavigationLink(
                "",
                destination: CardQuestionView(questionIndex: 0).environmentObject(onboardingVM),
                isActive: $navigateToCards
            )
            .opacity(0)



            Spacer()
        }
        .padding()
        .background(LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}


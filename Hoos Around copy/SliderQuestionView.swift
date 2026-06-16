import SwiftUI

struct SliderQuestionView: View {
    let questionIndex: Int
    @State private var sliderValue: Double = 50   // 0...100 UI scale
    @State private var navigateToNext = false

    @EnvironmentObject var onboardingVM: OnboardingViewModel

    private let questions: [SliderQuestion] = SliderQuestion.all

    var body: some View {
        let current = questions[questionIndex]

        VStack(spacing: 24) {
            Spacer()

            Text(current.prompt)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(feedbackText(for: sliderValue, labels: current.feedback))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack {
                Text(current.leftLabel).foregroundColor(.white.opacity(0.6))
                Slider(value: $sliderValue, in: 0...100, step: 1)
                Text(current.rightLabel).foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal)

            Button(questionIndex < questions.count - 1 ? "Next" : "Continue") {
                // 1) Legacy: keep first 5 answers in sliderResponses (0..100)
                if questionIndex < 5 {
                    onboardingVM.sliderResponses[questionIndex] = Int(sliderValue)
                }

                // 2) New: always map to –3, –1.5, 0, +1.5, +3 and store in quizResponses[0...9]
                let mapped = mapToFivePoint(value: sliderValue)
                ensureQuizCapacity()
                onboardingVM.quizResponses[questionIndex] = mapped

                navigateToNext = true
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            NavigationLink(
                destination: nextView(),
                isActive: $navigateToNext
            ) { EmptyView() }
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onAppear {
            // Pre-populate UI slider if user goes back/forward.
            if questionIndex < 5, onboardingVM.sliderResponses.indices.contains(questionIndex) {
                sliderValue = Double(onboardingVM.sliderResponses[questionIndex])
            } else if onboardingVM.quizResponses.indices.contains(questionIndex) {
                // Map existing –3..+3 back to 0..100 to restore the UI position
                sliderValue = mapBackFromFivePoint(onboardingVM.quizResponses[questionIndex])
            }
        }
    }

    // MARK: - Helpers

    private func ensureQuizCapacity() {
        if onboardingVM.quizResponses.count < questions.count {
            onboardingVM.quizResponses = Array(onboardingVM.quizResponses.prefix(questions.count)
                + Array(repeating: 0, count: questions.count - onboardingVM.quizResponses.count))
        }
    }

    private func mapToFivePoint(value: Double) -> Double {
        switch value {
        case 0..<20:   return -3.0
        case 20..<40:  return -1.5
        case 40..<60:  return 0.0
        case 60..<80:  return 1.5
        default:       return 3.0
        }
    }

    private func mapBackFromFivePoint(_ v: Double) -> Double {
        // Map center of each bucket back into 0..100 for UI restoration
        switch v {
        case ..<(-2.0): return 10
        case -2.0..<(-0.5): return 30
        case -0.5..<0.5: return 50
        case 0.5..<2.0: return 70
        default: return 90
        }
    }

    private func feedbackText(for value: Double, labels: [String]) -> String {
        switch value {
        case 0..<20: return labels[0]
        case 20..<40: return labels[1]
        case 40..<60: return labels[2]
        case 60..<80: return labels[3]
        default: return labels[4]
        }
    }

    @ViewBuilder
    private func nextView() -> some View {
        if questionIndex < questions.count - 1 {
            SliderQuestionView(questionIndex: questionIndex + 1).environmentObject(onboardingVM)
        } else {
            // After Q10 → Review screen (no more open-ended)
            PersonalityReviewView().environmentObject(onboardingVM)
        }
    }
}


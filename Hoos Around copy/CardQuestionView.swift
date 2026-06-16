import SwiftUI

struct CardQuestionView: View {
    let questionIndex: Int
    @EnvironmentObject var onboardingVM: OnboardingViewModel

    @State private var pickedRight: Bool? = nil
    @State private var navigateNext = false

    private var question: CardQuestion { CardQuestion.all[questionIndex] }
    private var isLast: Bool { questionIndex == CardQuestion.all.count - 1 }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)

            Text(question.prompt)
                .font(.title2.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Two big cards
            VStack(spacing: 14) {
                // TOP / FIRST option  ➜  LEFT tag
                Button {
                    pickedRight = false            // ← LEFT
                } label: {
                    AnswerRow(
                        text: question.leftText,
                        isSelected: pickedRight == false
                    )
                }

                // BOTTOM / SECOND option  ➜  RIGHT tag
                Button {
                    pickedRight = true             // ← RIGHT
                } label: {
                    AnswerRow(
                        text: question.rightText,
                        isSelected: pickedRight == true
                    )
                }
            }
            .padding(.horizontal)

            Spacer()

            Button(action: goForward) {
                Text(isLast ? "Review Results" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pickedRight == nil ? Color.white.opacity(0.35) : Color.white)
                    .foregroundColor(pickedRight == nil ? .white.opacity(0.7) : .purple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(pickedRight == nil)
            .padding(.horizontal)
            .padding(.bottom, 20)

            NavigationLink("", isActive: $navigateNext) {
                nextView()
                    .environmentObject(onboardingVM)
            }
            .hidden()
        }
        .background(
            LinearGradient(colors: [Color.purple, Color.black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onAppear {
            // restore selection if user navigates back
            if let stored = onboardingVM.cardAnswers[questionIndex] {
                pickedRight = stored
            }
        }
    }

    // MARK: - UI helpers

    @ViewBuilder
    private func nextView() -> some View {
        if isLast {
            PersonalityReviewView()
        } else {
            CardQuestionView(questionIndex: questionIndex + 1)
        }
    }

    private func goForward() {
        guard let pickedRight else { return }
        onboardingVM.recordCardAnswer(qIndex: questionIndex, pickedRight: pickedRight)
        navigateNext = true
    }

    // This method is unused but left here as per instruction
    private func recordCardAnswer(forQuestion index: Int, selectedAnswer: Bool) {
        // Possibly legacy or placeholder
    }
}

// MARK: - UI pieces
private struct AnswerRow: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .foregroundColor(.purple)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.purple)
                    .transition(.scale)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(isSelected ? 0.95 : 0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }
}


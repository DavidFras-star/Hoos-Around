import SwiftUI

struct PersonalityReviewView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var goToBio = false
    @State private var goToIntro = false // ADDED
    @State private var sentences: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            Text("Does this sound like you?")
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !sentences.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(sentences, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "quote.opening")
                                .foregroundColor(.white.opacity(0.8))
                            Text(line)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                // Loading state (briefly shows while we compute)
                ProgressView().tint(.white)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Retake") {
                    onboardingVM.resetAll()
                    goToIntro = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.20))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    goToBio = true
                } label: {
                    Text("Save & Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Color.white)
                .foregroundColor(.purple)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(sentences.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            NavigationLink(destination: BioEntryView().environmentObject(onboardingVM), isActive: $goToBio) {
                EmptyView()
            }.hidden()

            NavigationLink(destination: IntroToQuizView().environmentObject(onboardingVM), isActive: $goToIntro) {
                EmptyView()
            }.hidden() // ADDED
        }
        .background(
            LinearGradient(colors: [Color.purple, Color.black],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true) // ADDED
        .onAppear(perform: computeSentences)
    }

    // MARK: - Logic

    private func computeSentences() {
        let tags = onboardingVM.finalizeTagsFromVotes()
        let lines = onboardingVM.buildPersonalitySentences(from: tags)

        onboardingVM.vibeTags = tags
        onboardingVM.personalitySummarySentences = lines

        sentences = lines
    }
}


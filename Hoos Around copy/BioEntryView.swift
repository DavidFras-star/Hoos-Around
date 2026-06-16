import SwiftUI

struct BioEntryView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    // Local state
    @State private var bioText: String = ""
    @State private var canContinue: Bool = false
    @State private var goToInterests: Bool = false
    @State private var goNext = false

    private let maxChars = 320
    private let minChars = 20

    // Quick-start templates users can edit freely
    private let templates: [String] = [
        "I’m a \(Date().formatted(.dateTime.year())) student studying [major], into [interest 1] and [interest 2]. If you’re into [topic] or [activity], say hey.",
        "Studying [major]. You’ll usually find me at [club/org] or working on [project]. Looking to meet people who are into [topic].",
        "[Two adjectives] • [hobby 1], [hobby 2], [hobby 3]. I care about [value] and love [activity].",
        "Currently learning [class/skill]. Down to collaborate on [project idea] or compare notes on [topic].",
        "Member of [org/club]. Big on [value/goal]. Let’s connect if you’re into [topic] or [community]."
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Title
            VStack(spacing: 8) {
                Text("Write your bio")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("Keep it real—what you’re studying, what you’re into, and the kind of people you want to meet.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 24)

            // Template chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(templates, id: \.self) { t in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                bioText = t
                                validateAndClamp()
                            }
                        } label: {
                            Text(sampleLabel(for: t))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Text editor card
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $bioText)
                    .frame(minHeight: 150, maxHeight: 220)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .onChange(of: bioText) { _ in
                        validateAndClamp()
                    }

                HStack {
                    Text(charCountText())
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    if !canContinue {
                        Text("At least \(minChars) characters")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // Continue → InterestsPickerView
            Button("Continue") {
                let trimmed = bioText.trimmingCharacters(in: .whitespacesAndNewlines)
                onboardingVM.summaryText = trimmed
                goToInterests = true
            }
            .disabled(!canContinue)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canContinue ? Color.white : Color.white.opacity(0.3))
            .foregroundColor(canContinue ? .black : .white.opacity(0.7))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 24)

            // Hidden nav → Interests
            NavigationLink("", isActive: $goToInterests) {
                InterestsPickerView()
                    .environmentObject(onboardingVM)  // pass SAME VM forward
            }
            .hidden()

        }
        .onAppear {
            // Pre-fill from VM if user comes back
            bioText = onboardingVM.summaryText
            validate()
        }
        .background(
            LinearGradient(colors: [Color.purple, Color.black],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
    }

    // MARK: - Helpers

    private func sampleLabel(for template: String) -> String {
        if template.contains("learning") { return "Creator/Builder" }
        if template.contains("Member of") { return "Community/Values" }
        if template.contains("Two adjectives") { return "Human + Hobbies" }
        if template.contains("Studying") { return "Campus Focus" }
        return "Short & Punchy"
    }

    private func validateAndClamp() {
        if bioText.count > maxChars {
            bioText = String(bioText.prefix(maxChars))
        }
        validate()
    }

    private func validate() {
        let trimmed = bioText.trimmingCharacters(in: .whitespacesAndNewlines)
        canContinue = trimmed.count >= minChars
    }

    private func charCountText() -> String {
        "\(bioText.count)/\(maxChars)"
    }
}


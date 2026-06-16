import Foundation

/// The 10 card questions in order. IMPORTANT: This index order maps 1:1 to
/// OnboardingViewModel.cardMap for axis/tag tallying.
struct CardQuestion: Identifiable {
    let id: Int
    let prompt: String
    let leftText: String
    let rightText: String

    static let all: [CardQuestion] = [
        .init(
            id: 0,
            prompt: "In a group, I usually…",
            leftText: "Listen & observe",
            rightText: "Speak up & take the lead"
        ),
        .init(
            id: 1,
            prompt: "When making a big decision, I trust…",
            leftText: "Logic & facts",
            rightText: "Feelings & values"
        ),
        .init(
            id: 2,
            prompt: "I feel most aligned when life is…",
            leftText: "Structured & planned",
            rightText: "Spontaneous & go-with-the-flow"
        ),
        .init(
            id: 3,
            prompt: "I’m drawn more to…",
            leftText: "Big ideas & possibilities",
            rightText: "Practical details & what’s real"
        )
    ]
}


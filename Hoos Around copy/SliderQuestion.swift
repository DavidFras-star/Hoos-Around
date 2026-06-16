import Foundation

struct SliderQuestion {
    let prompt: String
    let leftLabel: String
    let rightLabel: String
    let feedback: [String]  // kept for UI feel; not used for scoring

    static let all: [SliderQuestion] = [
        // 1 — E–I
        SliderQuestion(
            prompt: "I recharge best when I’m...",
            leftLabel: "Alone",
            rightLabel: "With other people",
            feedback: [
                "You’re most at peace in your own space.",
                "You recharge best in quiet moments or with just one close friend.",
                "You’re somewhere in the middle — it depends on the day.",
                "You come alive around good people and good conversation.",
                "You thrive on connection — the more energy, the better."
            ]
        ),
        // 2 — N–S
        SliderQuestion(
            prompt: "I prefer conversations that are...",
            leftLabel: "Light & playful",
            rightLabel: "Deep & reflective",
            feedback: [
                "You keep it light — banter, laughs, good vibes only.",
                "You love easy conversation, but you go deeper when it feels right.",
                "You’re up for anything — playful or deep, depending on the moment.",
                "You’re drawn to meaning — you like when convos go beneath the surface.",
                "You crave connection that’s real, raw, and unfiltered."
            ]
        ),
        // 3 — J–P
        SliderQuestion(
            prompt: "I feel most aligned when life is...",
            leftLabel: "Flexible & spontaneous",
            rightLabel: "Structured & planned",
            feedback: [
                "You’re a go-with-the-flow type — you like when life surprises you.",
                "You like to keep plans loose so you can pivot.",
                "You can plan or pivot — you like to stay open but grounded.",
                "You feel calmer when you’ve got a plan to follow.",
                "You thrive on structure, routines, and having things organized."
            ]
        ),
        // 4 — E–I
        SliderQuestion(
            prompt: "In a group, I usually...",
            leftLabel: "Listen & observe",
            rightLabel: "Lead & speak up",
            feedback: [
                "You’re the quiet strength — tuned in, steady, and present.",
                "You observe first and speak when it matters — thoughtful energy.",
                "You’re flexible — sometimes you lead, sometimes you hold space.",
                "You’re a natural contributor — you like to keep things moving.",
                "You step up, speak out, and help set the tone."
            ]
        ),
        // 5 — T–F
        SliderQuestion(
            prompt: "When making a big decision, I trust...",
            leftLabel: "Feelings & values",
            rightLabel: "Logic & facts",
            feedback: [
                "You lead with empathy and how things feel for people.",
                "You care about impact on others even when weighing outcomes.",
                "You try to balance head and heart.",
                "You prioritize sound reasoning and clear criteria.",
                "You rely on objective analysis to choose the best path."
            ]
        ),
        // 6 — N–S
        SliderQuestion(
            prompt: "I’m drawn more to...",
            leftLabel: "Practical details",
            rightLabel: "Big ideas & possibilities",
            feedback: [
                "You notice what’s concrete and actionable.",
                "You keep ideas grounded in what works.",
                "You like the bridge between real and imagined.",
                "You’re excited by what could be.",
                "You live in concepts and connections."
            ]
        ),
        // 7 — J–P
        SliderQuestion(
            prompt: "My workspace tends to be...",
            leftLabel: "A bit messy & evolving",
            rightLabel: "Neat & organized",
            feedback: [
                "You like flexible setups that adapt as you go.",
                "A little chaos helps you stay creative.",
                "You keep things usable without over-optimizing.",
                "You prefer tidy tools in the right place.",
                "Orderly spaces help you focus."
            ]
        ),
        // 8 — J–P
        SliderQuestion(
            prompt: "When plans change last minute, I...",
            leftLabel: "Go with the flow",
            rightLabel: "Get stressed or frustrated",
            feedback: [
                "You adapt quickly and keep moving.",
                "You’re okay pivoting if the reason makes sense.",
                "It depends on the situation and timing.",
                "You prefer notice so you can recalibrate.",
                "You value stability and predictability."
            ]
        ),
        // 9 — N–S
        SliderQuestion(
            prompt: "I notice more about...",
            leftLabel: "What’s happening right now",
            rightLabel: "What could happen next",
            feedback: [
                "You’re anchored in the present facts.",
                "You tend to notice what’s directly observable.",
                "You toggle between now and next.",
                "You pattern-match toward the future.",
                "You see trajectories and possibilities first."
            ]
        ),
        // 10 — T–F
        SliderQuestion(
            prompt: "When people disagree, I care more about...",
            leftLabel: "Keeping harmony",
            rightLabel: "Finding the truth",
            feedback: [
                "You protect relationships and feelings.",
                "You aim for compassion while discussing differences.",
                "You want fairness for people and ideas.",
                "You weigh arguments carefully to be fair.",
                "You value objective truth most of all."
            ]
        )
    ]
}


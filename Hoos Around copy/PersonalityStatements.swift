import Foundation

// MARK: - Axes & Zones

/// The four averaged axes we compute from the 10-item quiz.
enum PersonalityAxis: CaseIterable {
    case EI   // Social Energy: Extraversion (+) ↔ Introversion (−)
    case NS   // Perspective: Intuition (+) ↔ Sensing/Practical (−)
    case TF   // Decision Style: Thinking/Logic (+) ↔ Feeling/Empathy (−)
    case JP   // Life Approach: Judging/Structured (+) ↔ Perceiving/Flexible (−)
}

/// Five-zone bucketing for each axis.
enum Zone {
    case stronglyLeft, slightlyLeft, neutral, slightlyRight, stronglyRight
}

struct PersonalityStatements {

    // MARK: - Zone thresholds (–3 ... +3)
    static func zone(for value: Double) -> Zone {
        switch value {
        case ..<(-2.0):                   return .stronglyLeft
        case -2.0 ... (-0.5):             return .slightlyLeft
        case (-0.5) ..< 0.5:              return .neutral
        case 0.5 ..< 2.0:                 return .slightlyRight
        default:                          return .stronglyRight
        }
    }

    // MARK: - 4×5 statement tables (exactly as provided)

    /// Social Energy (E–I)
    static func socialEnergy(_ z: Zone) -> String {
        switch z {
        case .stronglyLeft:
            return "I’m someone who recharges best alone and feels drained by too much social time."
        case .slightlyLeft:
            return "I’m someone who enjoys people, but I need quiet time to reset."
        case .neutral:
            return "I’m someone who can go either way — I enjoy company but also value my space."
        case .slightlyRight:
            return "I’m someone who feels energized by spending time with people I click with."
        case .stronglyRight:
            return "I’m someone who thrives in social settings and loves being around others."
        }
    }

    /// Perspective (N–S)
    static func perspective(_ z: Zone) -> String {
        switch z {
        case .stronglyLeft:
            return "I’m someone who stays grounded in facts and prefers what’s real over what’s abstract."
        case .slightlyLeft:
            return "I’m someone who likes creative ideas, but I stay focused on what actually works."
        case .neutral:
            return "I’m someone who balances imagination with realism — I dream, but I also plan."
        case .slightlyRight:
            return "I’m someone who often sees possibilities beyond what’s in front of me."
        case .stronglyRight:
            return "I’m someone who’s always thinking big, exploring ideas, and connecting patterns others might miss."
        }
    }

    /// Decision Style (T–F)
    static func decisionStyle(_ z: Zone) -> String {
        switch z {
        case .stronglyLeft:
            return "I’m someone who values clear reasoning and prefers to stay objective in decisions."
        case .slightlyLeft:
            return "I’m someone who leads with logic but still cares how things impact others."
        case .neutral:
            return "I’m someone who tries to find balance between fairness and feelings."
        case .slightlyRight:
            return "I’m someone who considers how others feel before making decisions."
        case .stronglyRight:
            return "I’m someone who leads with empathy and tends to follow my heart."
        }
    }

    /// Life Approach (J–P)
    static func lifeApproach(_ z: Zone) -> String {
        switch z {
        case .stronglyLeft:
            return "I’m someone who prefers to stay spontaneous and figure things out as I go."
        case .slightlyLeft:
            return "I’m someone who likes to leave room for change, even when I have a plan."
        case .neutral:
            return "I’m someone who enjoys some structure but can adapt when needed."
        case .slightlyRight:
            return "I’m someone who feels calmer when I have a plan to follow."
        case .stronglyRight:
            return "I’m someone who thrives on structure, routines, and having things organized."
        }
    }

    // MARK: - Short summary keyword mapping
    // Uses +/- thresholds around 0.5 to avoid “neutral” words.
    static func shortSummary(ei: Double, ns: Double, tf: Double, jp: Double) -> String {
        let eiWord = ei >= 0.5 ? "Friendly" : (ei <= -0.5 ? "Independent" : "Balanced")
        let nsWord = ns >= 0.5 ? "Dreamer"  : (ns <= -0.5 ? "Practical"   : "Grounded")
        let tfWord = tf >= 0.5 ? "Logical"  : (tf <= -0.5 ? "Empathetic"   : "Fair-minded")
        let jpWord = jp >= 0.5 ? "Planner"  : (jp <= -0.5 ? "Flexible"     : "Adaptable")

        // Example format: "Friendly Dreamer • Empathetic Planner"
        // Choose two most distinctive tokens (NS + TF by default), then append the JP nuance.
        let left = "\(eiWord) \(nsWord)"
        let right = "\(tfWord) \(jpWord)"
        return "\(left) • \(right)"
    }
}


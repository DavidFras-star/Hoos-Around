import Foundation

struct VibeTagEntry: Identifiable {
    var id: String { key }
    let key: String          // canonical key (e.g., "Chill")
    let name: String         // display name (same as key)
    let meaning: String
    let traits: [String]
    let groupRole: String
    let tagline: String
    let imageName: String    // name in Assets.xcassets (e.g., "owl_chill")
}

enum VibeTagContent {
    // Canonical keys (must match backend / quiz tags)
    static let canonicalKeys: [String] = [
        "Analyst", "Creative", "Adventurer", "Connector", "Listener",
        "Chill", "Expressive", "Open-Minded", "Leader", "Optimist"
    ]

    // Map of canonical key -> entry
    static let all: [String: VibeTagEntry] = {
        var m: [String: VibeTagEntry] = [:]

        m["Analyst"] = VibeTagEntry(
            key: "Analyst",
            name: "Analyst",
            
            meaning: "Looks for patterns and wants things to make sense before jumping in. Brings clarity through thoughtful questions and careful observation.",
            traits: [
                "Notices details others miss",
                "Enjoys problem-solving",
                "Asks “why” and “how”",
                "Prefers substance over hype",
                "Calm under pressure"
            ],
            groupRole: "Grounds decisions with logic and evidence; helps teams avoid avoidable mistakes.",
            tagline: "Think it through, then move.",
            imageName: "owl_analyst"
        )

        m["Creative"] = VibeTagEntry(
            key: "Creative",
            name: "Creative",
            
            meaning: "Plays with ideas and aesthetics; sees possibilities where others see limits.",
            traits: [
                "Loves making / remixing things",
                "Comfortable with ambiguity",
                "Brings fresh angles",
                "Values expression",
                "Follows sparks of curiosity"
            ],
            groupRole: "Injects novelty and helps groups break out of ruts.",
            tagline: "Let’s try a different angle.",
            imageName: "owl_creative"
        )

        m["Adventurer"] = VibeTagEntry(
            key: "Adventurer",
            name: "Adventurer",
    
            meaning: "Energized by exploring—places, people, ideas. Down to try something new.",
            traits: [
                "Spontaneous plans",
                "Thrives on momentum",
                "Says yes to experiences",
                "Comfortable being a beginner",
                "Encourages others to join"
            ],
            groupRole: "Kicks off plans and keeps energy high.",
            tagline: "Let’s go see.",
            imageName: "owl_adventurer"
        )

        m["Connector"] = VibeTagEntry(
            key: "Connector",
            name: "Connector",
            
            meaning: "Brings people together and helps groups feel cohesive.",
            traits: [
                "Introduces friends",
                "Remembers names/interests",
                "Checks in on the quiet ones",
                "Builds welcoming vibes",
                "Hosts naturally"
            ],
            groupRole: "Glue of the circle; makes everyone feel included.",
            tagline: "No one sits out.",
            imageName: "owl_connector"
        )

        m["Listener"] = VibeTagEntry(
            key: "Listener",
            name: "Listener",
            
            meaning: "Creates space for others to be heard; notices feelings under the surface.",
            traits: [
                "Asks thoughtful follow-ups",
                "Patient silence",
                "Reflects back what they heard",
                "Trustworthy",
                "Low-ego presence"
            ],
            groupRole: "Builds safety and depth; diffuses tension.",
            tagline: "I’m here—go on.",
            imageName: "owl_listener"
        )

        m["Chill"] = VibeTagEntry(
            key: "Chill",
            name: "Chill",
            
            meaning: "Steady, easygoing, and hard to rattle; keeps the temperature comfortable.",
            traits: [
                "Goes with the flow",
                "Calm in chaos",
                "Harmony-oriented",
                "Low-maintenance plans",
                "Enjoys simple hangs"
            ],
            groupRole: "The reset button; prevents drama from spiraling.",
            tagline: "Cool head, warm vibes.",
            imageName: "owl_chill"
        )

        m["Expressive"] = VibeTagEntry(
            key: "Expressive",
            name: "Expressive",
            
            meaning: "Shares thoughts and feelings openly; brings enthusiasm that’s contagious.",
            traits: [
                "Big reactions",
                "Storyteller",
                "Transparent emotions",
                "Encouraging hype friend",
                "Comfortable taking the mic"
            ],
            groupRole: "Raises energy and helps groups be honest.",
            tagline: "Say it out loud.",
            imageName: "owl_expressive"
        )

        m["Open-Minded"] = VibeTagEntry(
            key: "Open-Minded",
            name: "Open-Minded",
            
            meaning: "Curious and flexible; willing to update beliefs when shown something new.",
            traits: [
                "Asks “What am I missing?”",
                "Reads widely",
                "Tries unfamiliar things",
                "Respects different viewpoints",
                "Bridges disagreements"
            ],
            groupRole: "Keeps conversations expansive and warm.",
            tagline: "Show me another lens.",
            imageName: "owl_openminded"
        )

        m["Leader"] = VibeTagEntry(
            key: "Leader",
            name: "Leader",
            
            meaning: "Naturally organizes people toward action while keeping morale up.",
            traits: [
                "Sets direction",
                "Clarifies roles",
                "Checks in on people",
                "Takes responsibility",
                "Decisive when needed"
            ],
            groupRole: "Turns ideas into motion and keeps momentum.",
            tagline: "I’ll get us there.",
            imageName: "owl_leader"
        )

        m["Optimist"] = VibeTagEntry(
            key: "Optimist",
            name: "Optimist",
          
            meaning: "Spots the upside and helps people feel capable.",
            traits: [
                "Hopeful by default",
                "Reframes setbacks",
                "Celebrates small wins",
                "Encourages effort",
                "Believes in people"
            ],
            groupRole: "Protects morale; keeps groups moving through rough patches.",
            tagline: "We’ve got this.",
            imageName: "owl_optimist"
        )

        return m
    }()

    /// Case-insensitive lookup; trims whitespace.
    static func entry(for tag: String) -> VibeTagEntry? {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        // Fast path: exact
        if let e = all[trimmed] { return e }
        // Case-insensitive
        if let key = all.keys.first(where: { $0.compare(trimmed, options: .caseInsensitive) == .orderedSame }) {
            return all[key]
        }
        return nil
    }
}


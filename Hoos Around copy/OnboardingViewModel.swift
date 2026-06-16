import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Axis + Votes
enum Axis: String, CaseIterable, Hashable {
    case EI, TF, JP, NS
}

struct AxisVotes {
    var left: Int = 0
    var right: Int = 0
    var total: Int { left + right }
}

struct CardQMap {
    let axis: Axis
    let leftTag: String
    let rightTag: String
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    // Onboarding quiz answers (legacy slider + open)
    @Published var avatarImage: UIImage? = nil
    @Published var avatarUrl: String? = nil
    @Published var sliderResponses: [Int] = Array(repeating: 50, count: 5)
    @Published var openResponses: [String] = Array(repeating: "", count: 5)
    @Published var profileAvatar: UIImage? = nil
    // 0–100 results toward the RIGHT label: EI (Introverted), NS (Realist), TF (Empathetic), JP (Structured)
    @Published var quizResults100: [String: Double] = [:]

    // Old 10-question Likert (kept for back-compat; not used by cards)
    @Published var quizResponses: [Double] = Array(repeating: 0, count: 10)

    // NEW personality outputs
    @Published var personalityStatements: [String: String] = [:]
    @Published var shortSummary: String = ""
    @Published var personalitySummarySentences: [String] = []

    // ====== NEW: Card-based voting state (deterministic, no AI) ======
    @Published var votes: [Axis: AxisVotes] = [
        .EI: AxisVotes(), .TF: AxisVotes(), .JP: AxisVotes(), .NS: AxisVotes()
    ]
    @Published var cardAnswers: [Bool?] = Array(repeating: nil, count: 4)
    @Published var pendingTieAxes: [Axis] = []

    let cardMap: [CardQMap] = [
        // 0: Energy (EI)
        .init(axis: .EI, leftTag: "INTROVERT",   rightTag: "EXTROVERT"),
        // 1: Decision (TF)
        .init(axis: .TF, leftTag: "LOGIC",       rightTag: "VALUES"),
        // 2: Lifestyle (JP)
        .init(axis: .JP, leftTag: "STRUCTURED",  rightTag: "SPONTANEOUS"),
        // 3: Perspective (NS)
        .init(axis: .NS, leftTag: "DREAMER",     rightTag: "REALIST")
    ]

    // ====== Existing user profile info ======
    @Published var email: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var major: String = ""
    @Published var orgs: String = ""
    @Published var year: String = ""
    @Published var openTo: String = ""
    @Published var interests: [String] = []
    @Published var involvement: [String] = []
    @Published var bio: String = ""

    // Photos
    @Published var profilePhotos: [UIImage?] = [nil, nil, nil, nil]
    @Published var photoUrl: String = ""
    @Published var photoUrls: [String] = []

    // 🔹 NEW: local-only videos (for onboarding preview playback)
    @Published var localVideoURLs: [URL?] = [nil, nil, nil, nil]

    // Summary & tags
    @Published var summaryText: String = ""
    @Published var vibeTags: [String] = []

    // Location
    @Published var location: [String: Double] = ["lat": 0.0, "lng": 0.0]

    @Published var onboardingComplete: Bool = false

    private var userListener: ListenerRegistration?

    var userId: String? { Auth.auth().currentUser?.uid }

    var fullName: String {
        if !firstName.isEmpty && !lastName.isEmpty { return "\(firstName) \(lastName)" }
        if !firstName.isEmpty { return firstName }
        return ""
    }

    var safeFullName: String {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let combo = [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return combo.isEmpty ? "Unknown" : combo
    }

    var primaryPhotoUrl: String {
        if let first = photoUrls.first, !first.isEmpty { return first }
        return photoUrl
    }

    var orgsArray: [String] {
        orgs
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    let majors: [(category: String, options: [String])] = [
        ("STEM", ["Biology", "Chemistry", "Physics", "Mathematics", "Computer Science"]),
        ("Business/Finance/Management", ["Business Administration", "Accounting"]),
        ("Social Sciences & Psychology", ["Psychology", "Sociology"]),
        ("Humanities", ["English", "History"]),
        ("Communication, Media, Arts", ["Journalism", "Media Studies"]),
        ("Health & Medical", ["Nursing", "Public Health"]),
        ("Education", ["Elementary Education", "Secondary Education"])
    ]

    let years: [String] = ["Freshman", "Sophomore", "Junior", "Senior", "Grad Student"]

    func allAnswers() -> [String] {
        var combined: [String] = []
        for (i, v) in sliderResponses.enumerated() { combined.append("Slider Q\(i+1): \(v)") }
        for (i, t) in openResponses.enumerated() { combined.append("Open Q\(i+1): \(t)") }
        return combined
    }

    func setVibeTagsIfNeeded(_ newTags: [String]) {
        if vibeTags.isEmpty { vibeTags = newTags }
    }

    func computeAxes() -> (E_I: Double, N_S: Double, T_F: Double, J_P: Double) {
        let q = quizResponses
        guard q.count == 10 else { return (0,0,0,0) }
        let E_I = (q[0] + q[3]) / 2.0
        let N_S = (q[1] + q[5] + q[8]) / 3.0
        let T_F = (q[4] + q[9]) / 2.0
        let J_P = (q[2] + q[6] + q[7]) / 3.0
        return (E_I, N_S, T_F, J_P)
    }

    func dominantTag(for value: Double, left leftTag: String, right rightTag: String, threshold: Double = 0.5) -> String {
        if value >= threshold { return rightTag }
        if value <= -threshold { return leftTag }
        return (value >= 0) ? rightTag : leftTag
    }

    func deriveVibeTags() -> [String] {
        let axes = computeAxes()
        let energy       = dominantTag(for: axes.E_I, left: "EXTROVERT",   right: "INTROVERT")
        let decision     = dominantTag(for: axes.T_F, left: "LOGIC",       right: "VALUES")
        let lifestyle    = dominantTag(for: axes.J_P, left: "SPONTANEOUS", right: "STRUCTURED")
        let perspective  = dominantTag(for: axes.N_S, left: "DREAMER",     right: "REALIST")
        return [energy, decision, lifestyle, perspective]
    }

    func buildPersonalitySentences(from tags: [String]) -> [String] {
        guard tags.count == 4 else { return [] }
        let energy      = tags[0].uppercased()
        let decision    = tags[1].uppercased()
        let lifestyle   = tags[2].capitalized
        let perspective = tags[3].uppercased()

        let s1 = (energy == "INTROVERT")
            ? "I’m an INTROVERT and I recharge by spending time alone."
            : "I’m an EXTROVERT and I recharge by spending time with others."

        let s2 = (decision == "LOGIC")
            ? "I make decisions guided by clarity and LOGIC."
            : "I make decisions guided by intuition and VALUES."

        let s3 = "I feel most aligned when life is \(lifestyle)."

        let s4 = (perspective == "REALIST")
            ? "I’m a REALIST. I tend to see the world as it is."
            : "I’m a DREAMER. I tend to see the world as it could be."

        return [s1, s2, s3, s4]
    }

    func recordCardAnswer(qIndex: Int, pickedRight: Bool) {
        guard cardMap.indices.contains(qIndex) else { return }
        let map = cardMap[qIndex]
        if pickedRight {
            votes[map.axis, default: AxisVotes()].right += 1
        } else {
            votes[map.axis, default: AxisVotes()].left += 1
        }
        cardAnswers[qIndex] = pickedRight
    }

    // MARK: - Simplified text-based version (no left/right confusion)
    func recordCardAnswer(forQuestion question: String, selectedAnswer: String) {
        let lowerQ = question.lowercased()
        let lowerA = selectedAnswer.lowercased()

        if lowerQ.contains("group") { // EI
            if lowerA.contains("listen") || lowerA.contains("observe") {
                votes[.EI, default: AxisVotes()].left += 1 // INTROVERT
            } else if lowerA.contains("lead") || lowerA.contains("speak") {
                votes[.EI, default: AxisVotes()].right += 1 // EXTROVERT
            }

        } else if lowerQ.contains("decision") { // TF
            if lowerA.contains("logic") || lowerA.contains("facts") {
                votes[.TF, default: AxisVotes()].left += 1 // LOGIC
            } else if lowerA.contains("values") || lowerA.contains("feelings") {
                votes[.TF, default: AxisVotes()].right += 1 // VALUES
            }

        } else if lowerQ.contains("aligned") { // JP
            if lowerA.contains("structured") || lowerA.contains("planned") {
                votes[.JP, default: AxisVotes()].left += 1 // STRUCTURED
            } else if lowerA.contains("spontaneous") || lowerA.contains("flow") {
                votes[.JP, default: AxisVotes()].right += 1 // SPONTANEOUS
            }

        } else if lowerQ.contains("drawn") { // NS
            if lowerA.contains("ideas") || lowerA.contains("possibilities") {
                votes[.NS, default: AxisVotes()].left += 1 // DREAMER
            } else if lowerA.contains("practical") || lowerA.contains("real") {
                votes[.NS, default: AxisVotes()].right += 1 // REALIST
            }
        }
    }

    func checkForTies() -> [Axis] {
        pendingTieAxes = [] // with 1 Q per axis, ties are impossible
        return []
    }

    func applyTieBreaker(axis: Axis, pickedRight: Bool) {
        guard axis == .EI || axis == .TF else { return }
        if pickedRight {
            votes[axis, default: AxisVotes()].right += 1
        } else {
            votes[axis, default: AxisVotes()].left += 1
        }
        pendingTieAxes.removeAll { $0 == axis }
    }

    func finalizeTagsFromVotes() -> [String] {
        func pickTag(for axis: Axis) -> String {
            let v = votes[axis, default: AxisVotes()]
            let leftWins = v.left > v.right
            switch axis {
            case .EI: return leftWins ? "INTROVERT"   : "EXTROVERT"
            case .TF: return leftWins ? "LOGIC"       : "VALUES"
            case .JP: return leftWins ? "STRUCTURED"  : "SPONTANEOUS"
            case .NS: return leftWins ? "DREAMER"     : "REALIST"
            }
        }

        let energy      = pickTag(for: .EI)
        let decision    = pickTag(for: .TF)
        let lifestyle   = pickTag(for: .JP)
        let perspective = pickTag(for: .NS)
        return [energy, decision, lifestyle, perspective]
    }

    func quizResultsFromVotes() -> [String: Double] {
        func pctRight(_ v: AxisVotes) -> Double {
            guard v.total > 0 else { return 50 }
            return (Double(v.right) / Double(v.total)) * 100.0
        }
        return [
            "E_I": pctRight(votes[.EI] ?? AxisVotes()), // toward EXTROVERT
            "T_F": pctRight(votes[.TF] ?? AxisVotes()), // toward VALUES
            "J_P": pctRight(votes[.JP] ?? AxisVotes()), // toward SPONTANEOUS
            "N_S": pctRight(votes[.NS] ?? AxisVotes())  // toward DREAMER
        ]
    }

    func loadFromFirestore(data: [String: Any]) {
        print("📡 [VM] loadFromFirestore at", Date(), "keys:", data.keys.sorted())

        if let tags = data["vibeTags"] as? [String], !tags.isEmpty {
            vibeTags = tags
        }

        if let bio = data["bio"] as? String {
            summaryText = bio
        } else if let legacy = data["vibeSummary"] as? String {
            summaryText = legacy
        }

        if let first = data["firstName"] as? String { firstName = first }
        if let last  = data["lastName"]  as? String { lastName = last }
        if let majorVal = data["major"] as? String { major = majorVal }

        if let orgList = data["orgs"] as? [String] {
            orgs = orgList.joined(separator: ", ")
        } else if let orgsVal = data["orgs"] as? String {
            orgs = orgsVal
        } else {
            orgs = ""
        }

        if let yearVal  = data["year"]  as? String { year  = yearVal }
        if let openToVal = data["openTo"] as? String { openTo = openToVal }

        if let bioVal = data["bio"] as? String {
            bio = bioVal
        } else if let legacy = data["vibeSummary"] as? String {
            bio = legacy
        }

        if let ints = data["interests"] as? [String] { self.interests = ints }
        if let inv  = data["involvement"] as? [String] { self.involvement = inv }

        if let urls = data["photoUrls"] as? [String] { photoUrls = urls }
        if let legacy = data["photoUrl"] as? String, !legacy.isEmpty {
            photoUrl = legacy
            if photoUrls.isEmpty { photoUrls = [legacy] }
        }

        if let loc = data["location"] as? [String: Double],
           let lat = loc["lat"], let lng = loc["lng"] {
            location = ["lat": lat, "lng": lng]
        }

        onboardingComplete = (data["onboardingComplete"] as? Bool) ?? false

        profilePhotos = [nil, nil, nil, nil]

        if let sliders = data["sliderResponses"] as? [Int], sliders.count == 5 { sliderResponses = sliders }
        if let openRes  = data["openResponses"] as? [String], openRes.count == 5 { openResponses = openRes }

        if let ps = data["personalityStatements"] as? [String: String] {
            personalityStatements = ps
        }
        if let ss = data["shortSummary"] as? String {
            shortSummary = ss
        }

        if let summaryLines = data["personalitySummarySentences"] as? [String], !summaryLines.isEmpty {
            personalitySummarySentences = summaryLines
        }
    }

    func loadFromFirestore(uid: String) {
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snap, _ in
            guard let self, let data = snap?.data() else { return }
            Task { @MainActor in self.loadFromFirestore(data: data) }
        }
    }

    func startUserListener() {
        stopUserListener()
        guard let uid = userId, !uid.isEmpty else { return }

        userListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self, let data = snap?.data() else { return }
                Task { @MainActor in self.loadFromFirestore(data: data) }
            }
    }

    func stopUserListener() {
        userListener?.remove()
        userListener = nil
    }

    func resetAll() {
        stopUserListener()

        sliderResponses = Array(repeating: 50, count: 5)
        openResponses = Array(repeating: "", count: 5)
        quizResponses = Array(repeating: 0, count: 10)
        personalityStatements = [:]
        shortSummary = ""
        personalitySummarySentences = []

        votes = [.EI: AxisVotes(), .TF: AxisVotes(), .JP: AxisVotes(), .NS: AxisVotes()]
        cardAnswers = Array(repeating: nil, count: 4)
        pendingTieAxes = []

        email     = ""
        firstName = ""
        lastName  = ""
        major     = ""
        orgs      = ""
        year      = ""
        openTo    = ""
        bio       = ""

        profilePhotos = [nil, nil, nil, nil]
        photoUrl      = ""
        photoUrls     = []
        localVideoURLs = [nil, nil, nil, nil]

        summaryText = ""
        vibeTags    = []

        location = ["lat": 0.0, "lng": 0.0]
        onboardingComplete = false
    }

    deinit {
        userListener?.remove()
    }
}




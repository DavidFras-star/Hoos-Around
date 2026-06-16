struct DiscoveryMatch: Codable, Identifiable {
    let uid: String
    let firstName: String
    let lastName: String
    let major: String
    let year: String
    let orgs: [String]
    let vibeTags: [String]
    let photoUrl: String
    let matchPercent: Double

    // NEW
    let sliderResponses: [Int]?
    
    var id: String { uid }
}

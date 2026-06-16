import Foundation

struct WaveRequest: Identifiable, Codable {
    var id: String = UUID().uuidString // Will be overwritten after decoding
    var fromUserId: String
    var fromName: String
    var fromPhotoUrl: String?
    var timestamp: TimeInterval

    // CodingKeys excludes `id` so it's not required in Firestore
    enum CodingKeys: String, CodingKey {
        case fromUserId
        case fromName
        case fromPhotoUrl
        case timestamp
    }
    
    // MARK: - Custom initializer for manual creation
    init(
        id: String,
        fromUserId: String,
        fromName: String,
        fromPhotoUrl: String?,
        timestamp: TimeInterval
    ) {
        self.id = id
        self.fromUserId = fromUserId
        self.fromName = fromName
        self.fromPhotoUrl = fromPhotoUrl
        self.timestamp = timestamp
    }
}


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestore

@MainActor
final class WavesRequestsViewModel: ObservableObject {
    @Published var waveRequests: [WaveRequest] = []
    private var listener: ListenerRegistration?

    // MARK: - Listener
    func startListening(forUserId userId: String) {
        guard !userId.isEmpty else {
            print("⚠️ [WavesRequestsVM] startListening: empty userId")
            waveRequests = []
            return
        }

        stopListening()

        let db = Firestore.firestore()
        listener = db.collection("users")
            .document(userId)
            .collection("waveRequests")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Firestore listener error:", error)
                    return
                }
                guard let docs = snapshot?.documents else {
                    self.waveRequests = []
                    return
                }

                self.waveRequests = docs.compactMap { doc in
                    // Try Codable first (matches your WaveRequest CodingKeys)
                    do {
                        var req = try doc.data(as: WaveRequest.self)
                        req.id = doc.documentID
                        return req
                    } catch {
                        // Fallback: be resilient to shape drift / type changes
                        let d = doc.data()

                        let fromUserId = (d["fromUserId"] as? String) ?? ""
                        let fromName   = (d["fromName"]   as? String) ?? ""
                        let fromPhoto  = d["fromPhotoUrl"] as? String

                        // Support either Firestore Timestamp or numeric seconds
                        let ts: TimeInterval = {
                            if let t = d["timestamp"] as? Timestamp {
                                return t.dateValue().timeIntervalSince1970
                            } else if let n = d["timestamp"] as? NSNumber {
                                return n.doubleValue
                            } else if let dval = d["timestamp"] as? Double {
                                return dval
                            } else {
                                return 0
                            }
                        }()

                        // Build a WaveRequest using your custom initializer
                        let req = WaveRequest(
                            id: doc.documentID,
                            fromUserId: fromUserId,
                            fromName: fromName,
                            fromPhotoUrl: fromPhoto,
                            timestamp: ts
                        )

                        return req.fromUserId.isEmpty ? nil : req
                    }
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Wave Back → delete request → send wave → create chat → seed userData → mark matched
    func waveBack(
        wave: WaveRequest,
        currentUser: OnboardingViewModel,
        completion: @escaping (String?) -> Void
    ) {
        let db = Firestore.firestore()

        // Snapshot main-actor state BEFORE closures
        guard let myId = currentUser.userId, !myId.isEmpty else {
            print("❌ waveBack: currentUser.userId is nil/empty")
            completion(nil)
            return
        }

        let myName     = currentUser.safeFullName
        let myPhoto    = currentUser.primaryPhotoUrl
        let myVibeTags = currentUser.vibeTags

        let partnerId = wave.fromUserId
        guard !partnerId.isEmpty else {
            print("❌ waveBack: partnerId (fromUserId) is empty")
            completion(nil)
            return
        }

        // 1) Delete incoming request
        print("🗑️ Attempting to delete wave request \(wave.id) for user \(myId)")
        db.collection("users")
            .document(myId)
            .collection("waveRequests")
            .document(wave.id)
            .delete { error in
                if let error { print("❌ Error deleting wave request:", error) }
                else { print("✅ Deleted wave request \(wave.id)") }

                // 2) Send wave back to sender
                self.sendWave(
                    to: partnerId,
                    fromUserId: myId,
                    fromName: myName,
                    fromPhotoUrl: myPhoto,
                    fromVibeTags: myVibeTags
                ) { success in
                    guard success else { completion(nil); return }

                    // Mark outgoing
                    db.collection("users")
                        .document(myId)
                        .setData(
                            ["outgoingWaveUserIds": FieldValue.arrayUnion([partnerId])],
                            merge: true
                        )

                    // 3) Create/get chat, then seed userData
                    FirebaseManager.shared.getOrCreateChat(with: partnerId) { chatId in
                        guard let chatId, !chatId.isEmpty else { completion(nil); return }

                        let fromNameTrim = wave.fromName.trimmingCharacters(in: .whitespacesAndNewlines)

                        self.fetchPartnerProfileBits(partnerId: partnerId) { fallbackName, fallbackPhoto, fallbackTags in
                            let finalPartnerName = !fromNameTrim.isEmpty ? fromNameTrim :
                                                   (!fallbackName.isEmpty ? fallbackName : "Unknown")

                            let partnerPhoto: String? =
                                (wave.fromPhotoUrl?.isEmpty == false) ? wave.fromPhotoUrl : fallbackPhoto

                            self.ensureChatUserData(
                                chatId: chatId,
                                currentUserId: myId,
                                currentUserName: myName,
                                currentUserPhotoUrl: myPhoto,
                                currentUserVibeTags: myVibeTags,
                                partnerId: partnerId,
                                partnerName: finalPartnerName,
                                partnerPhotoUrl: partnerPhoto,
                                partnerVibeTags: fallbackTags
                            )
                        }

                        // 4) Mark matched for both users
                        db.collection("users").document(myId).setData([
                            "matchedUserIds": FieldValue.arrayUnion([partnerId])
                        ], merge: true)
                        db.collection("users").document(partnerId).setData([
                            "matchedUserIds": FieldValue.arrayUnion([myId])
                        ], merge: true)

                        completion(chatId)
                    }
                }
            }
    }

    // MARK: - Send Wave helper
    private func sendWave(
        to recipientId: String,
        fromUserId: String,
        fromName: String,
        fromPhotoUrl: String,
        fromVibeTags: [String],
        completion: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()
        let waveRequest: [String: Any] = [
            "fromUserId":   fromUserId,
            "fromName":     fromName,
            "fromPhotoUrl": fromPhotoUrl,
            "fromVibeTags": fromVibeTags,
            "timestamp":    FieldValue.serverTimestamp()
        ]

        db.collection("users")
            .document(recipientId)
            .collection("waveRequests")
            .document(fromUserId)
            .setData(waveRequest) { error in
                if let error {
                    print("❌ Error sending wave back:", error)
                    completion(false)
                } else {
                    print("✅ Wave back sent to \(recipientId)")
                    completion(true)
                }
            }
    }

    // MARK: - Seed chat.userData
    private func ensureChatUserData(
        chatId: String,
        currentUserId: String,
        currentUserName: String,
        currentUserPhotoUrl: String,
        currentUserVibeTags: [String],
        partnerId: String,
        partnerName: String,
        partnerPhotoUrl: String?,
        partnerVibeTags: [String]
    ) {
        let db = Firestore.firestore()

        let meName   = currentUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mePhotoS = currentUserPhotoUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let mePhoto  = mePhotoS.lowercased().hasPrefix("http") ? mePhotoS : ""

        let themNameS  = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let themPhotoS = (partnerPhotoUrl ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let themPhoto  = themPhotoS.lowercased().hasPrefix("http") ? themPhotoS : ""

        let me: [String: Any] = [
            "name": meName.isEmpty ? "Unknown" : meName,
            "photoUrl": mePhoto,
            "vibeTags": currentUserVibeTags
        ]
        let them: [String: Any] = [
            "name": themNameS.isEmpty ? "Unknown" : themNameS,
            "photoUrl": themPhoto,
            "vibeTags": partnerVibeTags
        ]

        db.collection("chats").document(chatId).setData([
            "users": [currentUserId, partnerId],
            "userData": [
                currentUserId: me,
                partnerId: them
            ],
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    // MARK: - Lightweight partner fetch
    private func fetchPartnerProfileBits(
        partnerId: String,
        completion: @escaping (_ name: String, _ photo: String, _ tags: [String]) -> Void
    ) {
        Firestore.firestore().collection("users").document(partnerId).getDocument { snap, _ in
            guard let u = snap?.data() else {
                completion("", "", [])
                return
            }
            let first = (u["firstName"] as? String) ?? ""
            let last  = (u["lastName"]  as? String) ?? ""
            let name  = [first, last].joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            let photo = (u["photoUrl"] as? String) ?? ((u["photoUrls"] as? [String])?.first ?? "")
            let tags  = (u["vibeTags"] as? [String]) ?? []
            completion(name, photo, tags)
        }
    }
}


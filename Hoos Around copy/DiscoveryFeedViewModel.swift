import Foundation
import Firebase
import FirebaseAppCheck
import FirebaseFunctions


class DiscoveryFeedViewModel: ObservableObject {
    @Published var matches: [DiscoveryMatch] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func fetchDiscoveryFeed(uid: String, lat: Double, lng: Double) {
        self.isLoading = true
        self.errorMessage = nil

        let callable = Functions.functions(region: "us-central1").httpsCallable("getDiscoveryFeedCallable")
        callable.call(["uid": uid, "lat": lat, "lng": lng]) { result, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            if let error = error as NSError? {
                print("❌ Callable error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let data = result?.data as? [String: Any],
                  let matchesArray = data["matches"] as? [[String: Any]] else {
                print("⚠️ Unexpected data format:", String(describing: result?.data))
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid response format"
                }
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: matchesArray)
                let matches = try JSONDecoder().decode([DiscoveryMatch].self, from: jsonData)
                DispatchQueue.main.async {
                    self.matches = matches
                }
                print("✅ Loaded \(matches.count) discovery matches")
            } catch {
                print("🧨 Decode error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode matches: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Send Wave
    func sendWave(
        to user: DiscoveryMatch,
        fromUserId: String,
        fromName: String,
        fromPhotoUrl: String
    ) {
        let recipientUid = user.uid
        print("Sending wave TO recipient uid:", recipientUid, "FROM sender uid:", fromUserId)
        if recipientUid == fromUserId {
            print("⚠️ ERROR: Tried to send wave to self! Check your match/user flow.")
        }

        let db = Firestore.firestore()
        let waveData: [String: Any] = [
            "fromUserId": fromUserId,
            "fromName": fromName,
            "fromPhotoUrl": fromPhotoUrl,
            "timestamp": Date().timeIntervalSince1970
        ]
        db.collection("users")
            .document(recipientUid)
            .collection("waveRequests")
            .addDocument(data: waveData) { error in
                if let error = error {
                    print("Error sending wave: \(error)")
                } else {
                    print("Wave sent to \(recipientUid) from \(fromUserId)")
                    db.collection("users").document(fromUserId).setData([
                        "outgoingWaveUserIds": FieldValue.arrayUnion([recipientUid])
                    ], merge: true)
                }
            }

        DispatchQueue.main.async {
            self.matches.removeAll { $0.uid == user.uid }
        }
    }
}


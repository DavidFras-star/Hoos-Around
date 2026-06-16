import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

final class FirebaseManager {
    static let shared = FirebaseManager()
    
    let auth = Auth.auth()
    let firestore = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Save user profile (completion)
    func saveUserProfile(uid: String, data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        firestore.collection("users").document(uid).setData(data, merge: true) { error in
            if let error = error { completion(.failure(error)) }
            else { completion(.success(())) }
        }
    }
    
    // MARK: - Save user profile (async)
    func saveUserProfile(uid: String, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { cont in
            self.saveUserProfile(uid: uid, data: data) { result in
                cont.resume(with: result)
            }
        }
    }
    
    // MARK: - Fetch user profile (completion)
    func fetchUserProfile(uid: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(
                    domain: "FirebaseManager",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "User profile not found."]
                )))
                return
            }
            completion(.success(data))
        }
    }
    
    // MARK: - Fetch user profile (async)
    func fetchUserProfile(uid: String) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { cont in
            self.fetchUserProfile(uid: uid) { result in
                cont.resume(with: result)
            }
        }
    }
    
    // MARK: - Sign out (completion)
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try auth.signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Sign out (async)
    func signOut() async throws {
        try await withCheckedThrowingContinuation { cont in
            self.signOut { result in
                cont.resume(with: result)
            }
        }
    }
    
    // MARK: - Media Upload Helpers (Images + Videos)

    func uploadAllProfilePhotosAndVideos(
        userId: String,
        profilePhotos: [UIImage?],
        localVideoURLs: [URL?],
        completion: @escaping ([String]) -> Void
    ) {
        let storageRef = Storage.storage().reference()
        var mediaURLs: [String] = Array(repeating: "", count: profilePhotos.count)
        let dispatchGroup = DispatchGroup()

        for index in 0..<profilePhotos.count {
            if let videoURL = localVideoURLs[safe: index], videoURL != nil {
                // Upload VIDEO
                dispatchGroup.enter()
                Task {
                    do {
                        let url = try await self.uploadProfileVideo(videoURL!, userId: userId, index: index)
                        mediaURLs[index] = url
                        print("✅ Uploaded video \(index): \(url)")
                    } catch {
                        print("❌ Error uploading video \(index): \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }


            } else if let image = profilePhotos[safe: index], image != nil {
                // Upload IMAGE
                dispatchGroup.enter()
                guard let imageData = image!.jpegData(compressionQuality: 0.8) else {
                    print("⚠️ Could not get JPEG data for image \(index)")
                    continue
                }
                let imageRef = storageRef.child("profilePhotos/\(userId)/photo\(index).jpg")

                imageRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        print("❌ Error uploading image \(index): \(error.localizedDescription)")
                        dispatchGroup.leave()
                        return
                    }

                    imageRef.downloadURL { url, error in
                        if let url = url {
                            mediaURLs[index] = url.absoluteString
                            print("✅ Uploaded image \(index): \(url.absoluteString)")
                        } else {
                            print("❌ Failed to get image URL \(index): \(error?.localizedDescription ?? "Unknown")")
                        }
                        dispatchGroup.leave()
                    }
                }

            } else {
                print("ℹ️ Slot \(index) empty — skipping.")
            }
        }

        dispatchGroup.notify(queue: .main) {
            let filtered = mediaURLs.filter { !$0.isEmpty }
            print("🎉 Finished uploading media: \(filtered)")
            completion(filtered)
        }
    }

    func uploadAllProfilePhotosAndVideos(
        userId: String,
        profilePhotos: [UIImage?],
        localVideoURLs: [URL?]
    ) async throws -> [String] {
        try await withCheckedThrowingContinuation { cont in
            self.uploadAllProfilePhotosAndVideos(userId: userId, profilePhotos: profilePhotos, localVideoURLs: localVideoURLs) { urls in
                cont.resume(returning: urls)
            }
        }
    }

    func uploadProfileVideo(_ videoURL: URL, userId: String, index: Int) async throws -> String {
        // Copy to a temporary location you can read
        let tmpDir = FileManager.default.temporaryDirectory
        let safeURL = tmpDir.appendingPathComponent("upload_\(UUID().uuidString).mp4")
        try FileManager.default.copyItem(at: videoURL, to: safeURL)

        // Load file into Data (small enough for short clips)
        let videoData = try Data(contentsOf: safeURL)
        let ref = storage.reference().child("profileVideos/\(userId)/video\(index).mp4")

        // Use putDataAsync instead of putFileAsync
        let _ = try await ref.putDataAsync(videoData, metadata: nil)
        let downloadURL = try await ref.downloadURL()

        // Clean up temporary file
        try? FileManager.default.removeItem(at: safeURL)

        print("✅ Uploaded video \(index): \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }



    func uploadAllProfilePhotos(_ photos: [UIImage?], userId: String) async throws -> [String] {
        var urls: [String] = []
        for (i, imageOpt) in photos.enumerated() {
            if let image = imageOpt, let data = image.jpegData(compressionQuality: 0.8) {
                let ref = storage.reference().child("profile_photos/\(userId)_\(i).jpg")
                let _ = try await ref.putDataAsync(data, metadata: nil)
                let url = try await ref.downloadURL()
                urls.append(url.absoluteString)
            }
        }
        return urls
    }

    
    // MARK: - Chat creation (completion style)
    func getOrCreateChat(with otherUserId: String, completion: @escaping (String?) -> Void) {
        guard let currentUserId = auth.currentUser?.uid else {
            completion(nil); return
        }
        let chatUsers = [currentUserId, otherUserId].sorted()
        let chatId = chatUsers.joined(separator: "_")
        let chatRef = firestore.collection("chats").document(chatId)
        
        chatRef.getDocument { (doc, _) in
            if let doc = doc, doc.exists {
                completion(chatId)
                return
            }
            self.fetchUserProfile(uid: currentUserId) { meResult in
                self.fetchUserProfile(uid: otherUserId) { themResult in
                    let me = (try? meResult.get()) ?? [:]
                    let them = (try? themResult.get()) ?? [:]
                    
                    func name(from data: [String: Any]) -> String {
                        let first = (data["firstName"] as? String ?? "").trimmingCharacters(in: .whitespaces)
                        let last  = (data["lastName"]  as? String ?? "").trimmingCharacters(in: .whitespaces)
                        let combined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
                        return combined.isEmpty ? (first.isEmpty ? "Unknown" : first) : combined
                    }
                    func bestPhotoUrl(from data: [String: Any]) -> String {
                        if let urls = data["photoUrls"] as? [String], let first = urls.first, !first.isEmpty {
                            return first
                        }
                        return data["photoUrl"] as? String ?? ""
                    }
                    let myPayload: [String: Any] = [
                        "name": name(from: me),
                        "photoUrl": bestPhotoUrl(from: me),
                        "vibeTags": me["vibeTags"] as? [String] ?? []
                    ]
                    let theirPayload: [String: Any] = [
                        "name": name(from: them),
                        "photoUrl": bestPhotoUrl(from: them),
                        "vibeTags": them["vibeTags"] as? [String] ?? []
                    ]
                    
                    let userData: [String: Any] = [
                        currentUserId: myPayload,
                        otherUserId:   theirPayload
                    ]
                    
                    chatRef.setData([
                        "users": chatUsers,
                        "userData": userData,
                        "createdAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp() // NEW: for ordering & visibility
                    ]) { err in
                        if let err = err {
                            print("Error creating chat: \(err)")
                            completion(nil)
                        } else {
                            completion(chatId)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Async wrapper for getOrCreateChat
    func getOrCreateChatAsync(with otherUserId: String) async throws -> String? {
        try await withCheckedThrowingContinuation { cont in
            self.getOrCreateChat(with: otherUserId) { chatId in
                cont.resume(returning: chatId)
            }
        }
    }
}

// MARK: - Location upsert
extension FirebaseManager {
    func upsertLocation(uid: String, lat: Double, lng: Double) async throws {
        try await firestore.collection("users").document(uid).setData(
            ["location": ["lat": lat, "lng": lng]],
            merge: true
        )
    }
}

// MARK: - Wave sending
extension FirebaseManager {
    func sendWave(
        to recipientUserId: String,
        from sender: (id: String, name: String, photoUrl: String, vibeTags: [String])
    ) async throws {
        let ref = firestore
            .collection("users")
            .document(recipientUserId)
            .collection("waveRequests")
            .document()
        
        try await ref.setData([
            "fromUserId": sender.id,
            "fromName": sender.name,
            "fromPhotoUrl": sender.photoUrl,
            "fromVibeTags": sender.vibeTags,
            "timestamp": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Wave back & create chat
    func waveBackAndCreateChat(
        to recipientUserId: String,
        from sender: (id: String, name: String, photoUrl: String, vibeTags: [String])
    ) async throws -> String? {
        // 1) Send a wave back (lightweight acknowledgement)
        try await sendWave(to: recipientUserId, from: sender)
        // 2) Create or fetch the chat deterministically
        guard let chatId = try await getOrCreateChatAsync(with: recipientUserId) else {
            return nil
        }
        // 3) Bump updatedAt so Chats queries surface it immediately
        try await firestore.collection("chats").document(chatId).setData(
            ["updatedAt": FieldValue.serverTimestamp()],
            merge: true
        )
        return chatId
    }
}

// MARK: - Safe array indexing helper
private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


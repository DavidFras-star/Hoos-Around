import Foundation
import FirebaseFunctions

class FirebaseFunctionsManager {
    static let shared = FirebaseFunctionsManager()
    private lazy var functions = Functions.functions(region: "us-central1")

    // MARK: - Helpers
    private func asFunctionsError(_ error: Error) -> Error {
        if let ns = error as NSError?,
           let details = ns.userInfo[FunctionsErrorDetailsKey] as? String,
           !details.isEmpty {
            return NSError(
                domain: "FirebaseFunctions",
                code: ns.code,
                userInfo: [NSLocalizedDescriptionKey: details]
            )
        }
        return error
    }

    // MARK: - Generate summary (unchanged signature)
    func generateSummary(with answers: [String], completion: @escaping (Result<String, Error>) -> Void) {
        let data = ["answers": answers]
        let callable = functions.httpsCallable("generateSummary")
        print("📡 Calling Firebase Function: generateSummary with data: \(data)")

        callable.call(data) { result, error in
            if let error = error {
                let e = self.asFunctionsError(error)
                print("❌ Firebase Function error:", e.localizedDescription)
                completion(.failure(e))
                return
            }

            // Log raw result for inspection
            if let raw = result?.data {
                print("🔥 Raw Firebase response:", raw)
            }

            if let dict = result?.data as? [String: Any],
               let summary = dict["summary"] as? String,
               !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                completion(.success(summary))
            } else {
                print("⚠️ Failed to parse summary from Firebase response")
                completion(.failure(NSError(
                    domain: "FirebaseFunctions",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid or empty summary from Firebase"])
                ))
            }
        }
    }

    // MARK: - Assign vibe tags (unchanged signature)
    func assignVibeTags(sliderValues: [Int], openAnswers: [String], completion: @escaping (Result<[String], Error>) -> Void) {
        let data: [String: Any] = [
            "sliderValues": sliderValues,
            "openAnswers": openAnswers
        ]
        let callable = functions.httpsCallable("assignVibeTags")
        print("📡 Calling Firebase Function: assignVibeTags with data: \(data)")

        callable.call(data) { result, error in
            if let error = error {
                let e = self.asFunctionsError(error)
                print("❌ Firebase Function error (tags):", e.localizedDescription)
                completion(.failure(e))
                return
            }

            // Log for inspection
            if let raw = result?.data {
                print("🔥 Raw vibe tag response:", raw)
            }

            if let dict = result?.data as? [String: Any],
               let tags = dict["tags"] as? [String],
               tags.count == 2 {
                completion(.success(tags))
            } else {
                print("⚠️ Failed to parse tags from Firebase response")
                completion(.failure(NSError(
                    domain: "FirebaseFunctions",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid or empty tags from Firebase"])
                ))
            }
        }
    }
}



import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Model
struct ChatSummary: Identifiable {
    let id: String          // chatId
    let partnerId: String
    let partnerName: String
    let partnerPhotoUrl: String
    let partnerVibeTags: [String]
    let updatedAt: Date?
}

// MARK: - ViewModel
final class ChatsListViewModel: ObservableObject {
    @Published var chats: [ChatSummary] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func startListening(for uid: String) {
        stopListening()

        listener = db.collection("chats")
            .whereField("users", arrayContains: uid) // removed .order(by:)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("⚠️ Chats listener error:", error.localizedDescription)
                    self.chats = []
                    return
                }

                let docs = snapshot?.documents ?? []

                var items: [ChatSummary] = docs.compactMap { doc in
                    let data = doc.data()
                    guard let users = data["users"] as? [String],
                          let partnerId = users.first(where: { $0 != uid }) else { return nil }

                    let userData = data["userData"] as? [String: Any] ?? [:]
                    let partnerData = userData[partnerId] as? [String: Any] ?? [:]

                    let name = (partnerData["name"] as? String) ?? "Unknown"
                    let photoUrl = (partnerData["photoUrl"] as? String) ?? ""
                    let tags = (partnerData["vibeTags"] as? [String]) ?? []

                    let updatedTs = data["updatedAt"] as? Timestamp
                    let updated = updatedTs?.dateValue()

                    return ChatSummary(
                        id: doc.documentID,
                        partnerId: partnerId,
                        partnerName: name,
                        partnerPhotoUrl: photoUrl,
                        partnerVibeTags: tags,
                        updatedAt: updated
                    )
                }

                // Client-side sort to avoid composite index requirement
                items.sort { (lhs, rhs) in
                    let l = lhs.updatedAt ?? .distantPast
                    let r = rhs.updatedAt ?? .distantPast
                    return l > r
                }

                self.chats = items
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        chats = []
    }

    deinit { listener?.remove() }
}

// MARK: - View
struct ChatsView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @StateObject private var vm = ChatsListViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Full-bleed gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if vm.chats.isEmpty {
                    // Empty state
                    VStack(spacing: 8) {
                        Spacer()
                        Text("No new chats")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(vm.chats) { chat in
                            NavigationLink {
                                ChatThreadView(chatId: chat.id, partnerId: chat.partnerId)
                            } label: {
                                ChatRow(chat: chat)
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(16)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            if let uid = onboardingVM.userId, !uid.isEmpty {
                vm.startListening(for: uid)
            } else {
                vm.stopListening()
            }
        }
        .onDisappear {
            vm.stopListening()
        }
    }
}

// MARK: - Row
private struct ChatRow: View {
    let chat: ChatSummary

    var body: some View {
        HStack(spacing: 12) {
            Avatar(urlString: chat.partnerPhotoUrl)
            VStack(alignment: .leading, spacing: 6) {
                Text(chat.partnerName.isEmpty ? "Unknown" : chat.partnerName)
                    .font(.headline)
                    .foregroundColor(.white)
                if !chat.partnerVibeTags.isEmpty {
                    Text(chat.partnerVibeTags.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct Avatar: View {
    let urlString: String

    var body: some View {
        Group {
            if let url = URL(string: urlString), !urlString.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .opacity(0.2)
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .opacity(0.2)
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ChatsView().environmentObject(OnboardingViewModel())
}


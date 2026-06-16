import SwiftUI
import Firebase
import FirebaseFirestore

struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let senderId: String
    let timestamp: Date
}

struct ChatThreadView: View {
    let chatId: String
    let partnerId: String

    @State private var partnerName: String = "Unknown"
    @State private var partnerPhotoUrl: String = ""
    @State private var partnerVibeTags: [String] = []

    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @EnvironmentObject var onboardingVM: OnboardingViewModel

    var body: some View {
        VStack {
            // Header – tap to view profile
            NavigationLink(destination: ProfileView(userId: partnerId, readOnly: true)) {
                HStack {
                    if partnerPhotoUrl.lowercased().hasPrefix("http"),
                       let url = URL(string: partnerPhotoUrl) {
                        AsyncImage(url: url) { image in image.resizable() } placeholder: {
                            Image(systemName: "person.crop.circle.fill").resizable().opacity(0.2)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable().opacity(0.2)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading) {
                        Text(partnerName.isEmpty ? "Unknown" : partnerName)
                            .font(.title2).bold().foregroundColor(.white)
                        if !partnerVibeTags.isEmpty {
                            Text(partnerVibeTags.joined(separator: " • "))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)

            // Convo starter
            HStack {
                Text("Convo Starter\nNeed a spark? Try asking:\n“What’s something you’ve been overthinking lately?”")
                    .font(.callout)
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
            .background(Color.purple.opacity(0.7))
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.bottom, 4)

            // Messages
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(messages) { msg in
                        HStack {
                            if msg.senderId == onboardingVM.userId { Spacer() }
                            Text(msg.text)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(msg.senderId == onboardingVM.userId ? Color.purple : Color.purple.opacity(0.3))
                                .cornerRadius(18)
                                .frame(maxWidth: 240, alignment: msg.senderId == onboardingVM.userId ? .trailing : .leading)
                            if msg.senderId != onboardingVM.userId { Spacer() }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Input
            HStack {
                TextField("Say something real. Or just say hey.", text: $newMessage)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                    .foregroundColor(.white)
                Button(action: sendMessage) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(newMessage.isEmpty ? .gray : .purple)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
            .background(Color.black.opacity(0.1))
        }
        .background(LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchPartnerInfo()
            listenForMessages()
        }
    }

    // MARK: - Fetch partner info from chat.userData
    // MARK: - Fetch partner info from chat.userData
    func fetchPartnerInfo() {
        let db = Firestore.firestore()

        // myId is optional in your VM; unwrap it up front
        guard let myId = onboardingVM.userId, !myId.isEmpty else { return }

        db.collection("chats").document(chatId).getDocument { doc, _ in
            guard let data = doc?.data() else { return }

            // Support either "userIds" or legacy "users"
            let idArray = (data["userIds"] as? [String]) ?? (data["users"] as? [String]) ?? []
            guard idArray.contains(myId) else { return }

            // Find the other user in the chat
            guard let partnerId = idArray.first(where: { $0 != myId }) else { return }

            if
                let userDataAll = data["userData"] as? [String: Any],
                let partnerData = userDataAll[partnerId] as? [String: Any]
            {
                let name  = (partnerData["name"] as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let photo = (partnerData["photoUrl"] as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let tags  = partnerData["vibeTags"] as? [String] ?? []

                DispatchQueue.main.async {
                    self.partnerName     = name.isEmpty ? "Unknown" : name
                    self.partnerPhotoUrl = photo
                    self.partnerVibeTags = tags
                }
            } else {
                DispatchQueue.main.async {
                    self.partnerName     = "Unknown"
                    self.partnerPhotoUrl = ""
                    self.partnerVibeTags = []
                }
            }
        }
    }


    // MARK: - Firestore Messages Listener
    func listenForMessages() {
        let db = Firestore.firestore()
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let newMessages: [ChatMessage] = docs.compactMap { doc in
                    let data = doc.data()
                    guard let text = data["text"] as? String,
                          let senderId = data["senderId"] as? String,
                          let ts = data["timestamp"] as? Timestamp else { return nil }
                    return ChatMessage(id: doc.documentID, text: text, senderId: senderId, timestamp: ts.dateValue())
                }
                DispatchQueue.main.async {
                    self.messages = newMessages
                }
            }
    }

    // MARK: - Send Message
    func sendMessage() {
        guard !newMessage.isEmpty else { return }
        let db = Firestore.firestore()
        let msgData: [String: Any] = [
            "text": newMessage,
            "senderId": onboardingVM.userId,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("chats").document(chatId).collection("messages").addDocument(data: msgData) { err in
            if err == nil {
                DispatchQueue.main.async { newMessage = "" }
            }
        }
    }
}

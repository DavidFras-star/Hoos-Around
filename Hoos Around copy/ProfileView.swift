import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - Notifications
extension Notification.Name {
    static let editVibeDidPickImage = Notification.Name("editVibeDidPickImage")
    // NEW: for tab switching + logout
    static let switchToHomeTab = Notification.Name("switchToHomeTab")
    static let requestLogout   = Notification.Name("requestLogout")
}

struct ProfileView: View {
    // Inputs
    var userId: String? = nil          // nil = viewing myself
    var readOnly: Bool = false         // true when viewing partner's profile
    // NEW: wave-back mode + callback to open chat
    var waveBackMode: Bool = false
    var onOpenChat: ((String) -> Void)? = nil
    
    // ViewModels
    @EnvironmentObject private var appVM: OnboardingViewModel   // shared (current user)
    @StateObject private var localVM = OnboardingViewModel()     // used for read-only partner
    
    // UI State
    @State private var showEdit = false
    @State private var isPhotoPickerPresented = false
    @State private var selectedPhotoSlot: Int? = nil
    @State private var isLoading = true
    @State private var loadError: String?
    
    // Wave state
    @State private var isWaving = false
    @State private var waveSent = false
    @State private var waveError: String?
    
    // Derived
    private var isViewingSelf: Bool { userId == nil || userId == appVM.userId }
    private var vm: OnboardingViewModel { isViewingSelf ? appVM : localVM }

    // MARK: - Alikeness (6 bars) helper
    private func computeAlikenessScores(
        currentSliders: [Int], currentTags: [String],
        viewedSliders: [Int], viewedTags: [String]
    ) -> [Double] {
        var scores: [Double] = []

        // 5 slider-based rows: 100 - |a - b|, clamped to 0...100
        let n = min(currentSliders.count, viewedSliders.count, 5)
        for i in 0..<n {
            let a = Double(currentSliders[i])
            let b = Double(viewedSliders[i])
            let sim = max(0, min(100, 100 - abs(a - b)))
            scores.append(sim)
        }
        // pad if needed
        while scores.count < 5 { scores.append(0) }

        // Shared Vibes: Jaccard
        let setA = Set(currentTags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        let setB = Set(viewedTags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        let unionCount = setA.union(setB).count
        let interCount = setA.intersection(setB).count
        let vibePercent: Double = (unionCount > 0) ? round((Double(interCount) / Double(unionCount)) * 100) : 0
        scores.append(vibePercent)

        return scores
    }

    // MARK: - Partner alikeness scores (only when viewing someone else)
    private var partnerAlikenessScores: [Double]? {
        guard !isViewingSelf else { return nil }
        let mySliders     = appVM.sliderResponses
        let myTags        = appVM.vibeTags
        let theirSliders  = localVM.sliderResponses
        let theirTags     = localVM.vibeTags
        guard mySliders.count == 5, theirSliders.count == 5 else { return nil }
        return computeAlikenessScores(
            currentSliders: mySliders, currentTags: myTags,
            viewedSliders: theirSliders, viewedTags: theirTags
        )
    }

    var body: some View {
        VStack {
            // Top bar only when viewing my own profile (not read-only)
            if isViewingSelf && !readOnly {
                HStack {
                    Button {
                        NotificationCenter.default.post(name: .switchToHomeTab, object: nil)
                    } label: {
                        Label("Home", systemImage: "chevron.left")
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button(role: .destructive) {
                        do {
                            try Auth.auth().signOut()
                            // NEW: fully reset onboarding state after logout
                            appVM.stopUserListener()
                            appVM.resetAll()
                        } catch {
                            print("Sign out error:", error)
                        }
                        NotificationCenter.default.post(name: .requestLogout, object: nil)
                    } label: {
                        Text("Logout")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            if isLoading {
                ProgressView()
            } else if let loadError {
                VStack(spacing: 8) {
                    Text("Couldn’t load profile")
                    Text(loadError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if isViewingSelf && !readOnly {
                        Button("Edit") { showEdit = true }
                    }
                }
            } else if !vm.firstName.isEmpty {
                ProfilePreviewView(
                    readOnly: !isViewingSelf || readOnly,
                    onEditTapped: { showEdit = true },
                    showsBackgroundGradient: false,
                    alikenessScores: partnerAlikenessScores
                )
                .environmentObject(vm)

                // ADD: Alikeness breakdown after photo strip

            } else {
                VStack(spacing: 8) {
                    Text("Profile incomplete")
                    if isViewingSelf && !readOnly {
                        Button("Finish Setup") { showEdit = true }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // fill screen
        .background(                                   // lighter purple profile gradient
            LinearGradient(colors: [Color.purple, Color.purple.opacity(0.7)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        // MARK: - Edit sheet (parent-owned)
        .sheet(isPresented: $showEdit) {
            EditVibeView(
                vm: vm,
                openPhotoPicker: { slot in
                    selectedPhotoSlot = slot
                    isPhotoPickerPresented = true
                }
            )
            .environmentObject(vm)
            .interactiveDismissDisabled(true)
        }
        // MARK: - Photo picker (parent-owned)
        .fullScreenCover(isPresented: $isPhotoPickerPresented, onDismiss: {
            selectedPhotoSlot = nil
        }) {
            ImagePicker { image in
                if let img = image, let slot = selectedPhotoSlot {
                    NotificationCenter.default.post(
                        name: .editVibeDidPickImage,
                        object: nil,
                        userInfo: ["slot": slot, "image": img]
                    )
                }
                isPhotoPickerPresented = false
                selectedPhotoSlot = nil
            }
        }
        // MARK: - State hygiene
        .onChange(of: showEdit) { newValue in
            if !newValue {
                isPhotoPickerPresented = false
                selectedPhotoSlot = nil
            }
        }
        // MARK: - Toolbar (unchanged: partner actions / edit)
        .toolbar {
            if isViewingSelf && !readOnly {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { showEdit = true }
                }
            }
            
            // Partner toolbar: Wave or Wave Back
            if !isViewingSelf {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            if waveBackMode {
                                // Wave Back → then open chat
                                if let chatId = try? await waveBackAndCreateChat() {
                                    waveSent = true
                                    waveError = nil
                                    onOpenChat?(chatId)
                                } else {
                                    waveError = "Could not wave back."
                                }
                            } else {
                                // Regular Wave
                                await wavePartnerIfPossible()
                            }
                        }
                    } label: {
                        if isWaving {
                            ProgressView()
                        } else {
                            Text(waveBackMode
                                 ? (waveSent ? "Waved" : "Wave Back")
                                 : (waveSent ? "Waved" : "Wave"))
                        }
                    }
                    .disabled(isWaving || waveSent)
                    .accessibilityIdentifier("waveButton")
                }
            }
        }
        // MARK: - Alerts
        .alert(waveBackMode ? "Wave back sent!" : "Wave sent!",
               isPresented: Binding(
                    get: { waveSent && waveError == nil },
                    set: { _ in }
               )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(waveBackMode
                 ? "We opened a chat so you can say hi."
                 : "They’ll see you in their Waves inbox.")
        }
        .alert("Couldn’t send wave", isPresented: Binding(
            get: { waveError != nil },
            set: { _ in waveError = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(waveError ?? "Unknown error")
        }
        // MARK: - Load target profile once
        .task {
            print("📡 Fetching profile for UID:", userId ?? appVM.userId ?? "nil")
            
            let targetUid = userId ?? appVM.userId
            guard let uid = targetUid, !uid.isEmpty else {
                loadError = "No signed-in user."
                isLoading = false
                return
            }
            
            FirebaseManager.shared.fetchUserProfile(uid: uid) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let raw):
                        var data = raw
                        // Safe defaults so UI/layout never computes with invalid values
                        data["orgs"] = data["orgs"] as? [String] ?? []
                        data["photoUrls"] = data["photoUrls"] as? [String] ?? []
                        vm.loadFromFirestore(data: data)
                        print("✅ Loaded Firestore data keys:", Array(data.keys))
                        print("✅ After load – vm.firstName:", vm.firstName)
                        isLoading = false
                    case .failure(let err):
                        loadError = err.localizedDescription
                        isLoading = false
                    }
                }
            }
            
            // Safety timeout to avoid infinite spinner
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                if isLoading {
                    loadError = "Loading took too long."
                    isLoading = false
                }
            }
        }
        .onAppear {
            print("📍 ProfileView onAppear – onboardingComplete:", appVM.onboardingComplete,
                  "photoUrls.count:", appVM.photoUrls.count)
        }
    }

    // MARK: - Wave helper (existing)
    private func wavePartnerIfPossible() async {
        guard !isViewingSelf,
              let recipientId = userId,
              let senderId = appVM.userId, !senderId.isEmpty else {
            return
        }
        
        isWaving = true
        defer { isWaving = false }
        
        // Sender display name
        let first = appVM.firstName.trimmingCharacters(in: .whitespaces)
        let last  = appVM.lastName.trimmingCharacters(in: .whitespaces)
        let composed = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        let name = composed.isEmpty ? (first.isEmpty ? "Unknown" : first) : composed
        
        // Primary photo URL
        let primaryFromArray = appVM.photoUrls.first ?? ""
        let photoUrl = primaryFromArray.isEmpty ? appVM.photoUrl : primaryFromArray
        
        let vibeTags: [String] = appVM.vibeTags
        
        do {
            try await FirebaseManager.shared.sendWave(
                to: recipientId,
                from: (id: senderId, name: name, photoUrl: photoUrl, vibeTags: vibeTags)
            )
            waveSent = true
            waveError = nil
        } catch {
            waveError = error.localizedDescription
        }
    }

    // MARK: - Wave Back helper (new)
    private func waveBackAndCreateChat() async throws -> String {
        guard !isViewingSelf,
              let partnerId = userId,
              let senderId = appVM.userId, !senderId.isEmpty else {
            throw NSError(domain: "ProfileView", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid users"])
        }
        
        isWaving = true
        defer { isWaving = false }
        
        // Build sender payload (same logic)
        let first = appVM.firstName.trimmingCharacters(in: .whitespaces)
        let last  = appVM.lastName.trimmingCharacters(in: .whitespaces)
        let composed = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        let name = composed.isEmpty ? (first.isEmpty ? "Unknown" : first) : composed
        
        let primaryFromArray = appVM.photoUrls.first ?? ""
        let photoUrl = primaryFromArray.isEmpty ? appVM.photoUrl : primaryFromArray
        let tags = appVM.vibeTags
        
        // Send wave back → create/open chat → return chatId
        if let chatId = try await FirebaseManager.shared.waveBackAndCreateChat(
            to: partnerId,
            from: (id: senderId, name: name, photoUrl: photoUrl, vibeTags: tags)
        ) {
            return chatId
        } else {
            throw NSError(domain: "ProfileView", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to open chat"])
        }
    }
}


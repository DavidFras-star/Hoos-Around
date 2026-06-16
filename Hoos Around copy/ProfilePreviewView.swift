import Foundation
import SwiftUI
import FirebaseFirestore
import AVKit

extension Color {
    static let cardBackground = Color.white.opacity(0.12)
}

struct ProfilePreviewView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel

    var readOnly: Bool = false
    var onEditTapped: (() -> Void)? = nil
    var showsBackgroundGradient: Bool = true
    var alikenessScores: [Double]? = nil

    @State private var isSaving = false
    @State private var goToApp = false
    @State private var errorMessage: String?

    private let defaultProfileImage = UIImage(named: "defaultProfile")

    // NEW — No more hero photo logic
    // Gallery = all user-provided photos (local OR remote)
    private struct GalleryItem: Identifiable {
        enum Kind {
            case local(image: UIImage)
            case remote(urlString: String)
        }
        let id = UUID().uuidString
        let kind: Kind
    }

    // NEW — This is simplified and correct now
    private var galleryItems: [GalleryItem] {
        var items: [GalleryItem] = []

        // add local photos
        for img in onboardingVM.profilePhotos.compactMap({ $0 }) {
            items.append(GalleryItem(kind: .local(image: img)))
        }

        // add remote photos (only when viewing a real saved user)
        for url in onboardingVM.photoUrls {
            items.append(GalleryItem(kind: .remote(urlString: url)))
        }

        return items
    }

    private var interestsLine: String { onboardingVM.interests.joined(separator: ", ") }

    @ViewBuilder
    private func verticalPhotoCard(_ item: GalleryItem) -> some View {
        let card: some View = Group {
            switch item.kind {

            case .local(let img):
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)

            case .remote(let urlString):
                if let url = URL(string: urlString) {
                    if url.pathExtension.lowercased() == "mp4" {
                        VideoPlayer(player: AVPlayer(url: url).configuredToLoopMuted())
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack { Color.white.opacity(0.12); ProgressView() }
                            case .success(let image):
                                image.resizable().aspectRatio(1, contentMode: .fill)
                            case .failure:
                                Image(uiImage: defaultProfileImage ?? UIImage())
                                    .resizable().aspectRatio(1, contentMode: .fill)
                            @unknown default:
                                Color.white.opacity(0.12)
                            }
                        }
                    }
                } else {
                    Image(uiImage: defaultProfileImage ?? UIImage())
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                }
            }
        }

        card
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .clipped()
            .shadow(radius: 4)
            .padding(.horizontal, 16)
    }


    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {

                // MARK: - PROFILE AVATAR
                if let avatar = onboardingVM.profileAvatar ?? defaultProfileImage {
                    Image(uiImage: avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(radius: 6)
                        .padding(.top, 20)
                        .padding(.bottom, 4)
                }




                // NAME + STATUS
                Text(onboardingVM.fullName)
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("\(onboardingVM.major) · \(onboardingVM.year)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("Active recently")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                }

                // VIBE TAGS CARD
                if !onboardingVM.vibeTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vibe Tags")
                            .font(.headline)
                            .foregroundColor(.white)

                        let titleCaseTags = onboardingVM.vibeTags.map { $0.lowercased().capitalized }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                            ForEach(titleCaseTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.purple)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // ABOUT ME CARD
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Me")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Text(onboardingVM.summaryText)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // HOBBIES CARD
                if !onboardingVM.interests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hobbies")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Text(interestsLine)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                // CAMPUS LIFE
                let involvementArray: [String] = {
                    if !onboardingVM.involvement.isEmpty {
                        return onboardingVM.involvement
                    }
                    return onboardingVM.orgs
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                }()

                if !involvementArray.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Campus Life")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        HStack {
                            ForEach(involvementArray, id: \.self) { item in
                                Text(item)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.purple)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                // GALLERY
                ForEach(galleryItems) { item in
                    verticalPhotoCard(item)
                }

                // CTA
                if !readOnly {
                    HStack(spacing: 12) {
                        Button("Edit") {
                            onEditTapped?()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.20))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button {
                            isSaving = true
                            Task { await handleLooksGoodAsync() }
                        } label: {
                            Group {
                                if isSaving {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                } else {
                                    Text("Looks Good")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                            }
                            .background(Color.white)
                            .foregroundColor(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isSaving)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Spacer(minLength: 32)
            }
        }
        .padding(.top, 0)
        .background(
            Group {
                if showsBackgroundGradient {
                    LinearGradient(
                        colors: [Color.purple, Color.black],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                } else {
                    Color.clear
                }
            }
        )
        .navigationDestination(isPresented: $goToApp) {
            TabBarView()
        }
        .alert(isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear { isSaving = false }
    }

    private func handleLooksGoodAsync() async {
        guard let userId = onboardingVM.userId, !userId.isEmpty else {
            errorMessage = "Missing user ID."
            isSaving = false
            return
        }

        do {
            let urls = try await FirebaseManager.shared.uploadAllProfilePhotosAndVideos(
                userId: userId,
                profilePhotos: onboardingVM.profilePhotos,
                localVideoURLs: onboardingVM.localVideoURLs
            )

            let q = onboardingVM.quizResponses
            let EI = q.count == 10 ? (q[0] + q[3]) / 2.0 : 0.0
            let NS = q.count == 10 ? (q[1] + q[5] + q[8]) / 3.0 : 0.0
            let TF = q.count == 10 ? (q[4] + q[9]) / 2.0 : 0.0
            let JP = q.count == 10 ? (q[2] + q[6] + q[7]) / 3.0 : 0.0
            let quizResults: [String: Any] = [
                "E_I": onboardingVM.quizResults100["EI"] ?? (EI * 25 + 50),
                "N_S": onboardingVM.quizResults100["NS"] ?? (NS * 25 + 50),
                "T_F": onboardingVM.quizResults100["TF"] ?? (TF * 25 + 50),
                "J_P": onboardingVM.quizResults100["JP"] ?? (JP * 25 + 50)
            ]

            let orgList = onboardingVM.involvement

            var data: [String: Any] = [
                "firstName": onboardingVM.firstName,
                "lastName": onboardingVM.lastName,
                "major": onboardingVM.major,
                "year": onboardingVM.year,
                "orgs": orgList,
                "involvement": onboardingVM.involvement,
                "interests": onboardingVM.interests,
                "vibeTags": onboardingVM.vibeTags,
                "personalitySummarySentences": onboardingVM.personalitySummarySentences,
                "bio": onboardingVM.summaryText,
                "sliderResponses": onboardingVM.sliderResponses,
                "openResponses": onboardingVM.openResponses,
                "photoUrls": urls,
                "location": onboardingVM.location,
                "timestamp": FieldValue.serverTimestamp(),
                "onboardingComplete": true,
                "quizResults": quizResults
            ]

            if !onboardingVM.personalityStatements.isEmpty {
                data["personalityStatements"] = onboardingVM.personalityStatements
            }
            if !onboardingVM.shortSummary.isEmpty {
                data["shortSummary"] = onboardingVM.shortSummary
            }

            try await FirebaseManager.shared.saveUserProfile(uid: userId, data: data)

            onboardingVM.photoUrls = urls
            onboardingVM.onboardingComplete = true

            isSaving = false
            goToApp = true
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }

    private func urlIfExists(in array: [URL?], at index: Int) -> URL? {
        guard array.indices.contains(index) else { return nil }
        return array[index]
    }
}

private extension AVPlayer {
    func configuredToLoopMuted() -> AVPlayer {
        isMuted = true
        actionAtItemEnd = .none
        if let item = currentItem {
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                   object: item, queue: .main) { [weak self] _ in
                self?.seek(to: .zero)
                self?.play()
            }
        }
        play()
        return self
    }
}


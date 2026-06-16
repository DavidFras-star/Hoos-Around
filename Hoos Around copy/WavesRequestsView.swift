import SwiftUI
import FirebaseFirestore

struct WavesRequestsView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @StateObject private var viewModel = WavesRequestsViewModel()

    // Navigation state
    @State private var navigateToChat = false
    @State private var selectedChatId: String?
    @State private var selectedPartnerId: String?

    var body: some View {
        NavigationView {
            ZStack {
                // Full-bleed background behind everything in this screen
                LinearGradient(colors: [Color.purple, Color.black],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                Group {
                    if viewModel.waveRequests.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Text("No waves yet 👋")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("When someone waves at you, it’ll show up here.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.clear) // keep clear so gradient shows
                    } else {
                        List {
                            ForEach(viewModel.waveRequests) { wave in
                                NavigationLink {
                                    ProfileView(
                                        userId: wave.fromUserId,
                                        readOnly: true,
                                        waveBackMode: true,
                                        onOpenChat: { chatId in
                                            // Programmatic navigation to chat thread
                                            selectedChatId = chatId
                                            selectedPartnerId = wave.fromUserId
                                            navigateToChat = true
                                        }
                                    )
                                    .environmentObject(onboardingVM)
                                } label: {
                                    // Translucent lilac card, like Home
                                    WaveRow(wave: wave)
                                        .padding()
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(16)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden) // show gradient behind list
                        .background(Color.clear)
                    }
                }
                // Hidden link that triggers when a Wave Back succeeds
                NavigationLink(
                    destination: ChatThreadView(
                        chatId: selectedChatId ?? "",
                        partnerId: selectedPartnerId ?? ""
                    ),
                    isActive: $navigateToChat
                ) { EmptyView() }
                .hidden()
            }
            // Nav bar chrome: avoid any white slivers
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            // Start listening once we have a valid userId
            if let uid = onboardingVM.userId, !uid.isEmpty {
                viewModel.startListening(forUserId: uid)
            } else {
                viewModel.stopListening()
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
}

private struct WaveRow: View {
    let wave: WaveRequest

    var body: some View {
        HStack(spacing: 12) {
            Avatar(urlString: wave.fromPhotoUrl ?? "")
            VStack(alignment: .leading, spacing: 6) {
                Text(wave.fromName.isEmpty ? "Unknown" : wave.fromName)
                    .font(.headline)
                    .foregroundColor(.white) // match Home card text
                // If you later re-add tags to the model, show them here.
                // For now your model has no fromVibeTags, so omit.
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


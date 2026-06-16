import SwiftUI
import CoreLocation

struct HomeView: View {
    // Use the shared VM from the environment (don’t create a new one here)
    @EnvironmentObject var onboardingVM: OnboardingViewModel

    // Own your feed/location state locally
    @StateObject private var viewModel = DiscoveryFeedViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var didUpsertLocation = false   // ← added

    var body: some View {
        NavigationStack {   // ← added
            VStack {
                if viewModel.isLoading {
                    ProgressView().padding(.top, 48)
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding(.top, 48)
                } else {
                    Text("Here’s \(viewModel.matches.count) people nearby who match your energy right now.")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                        .padding(.bottom, 24)
                        .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 22) {
                            ForEach(viewModel.matches) { match in
                                NavigationLink {
                                    ProfileView(userId: match.uid, readOnly: true)
                                        .environmentObject(onboardingVM)
                                } label: {
                                    DiscoveryMatchCard(
                                        match: match,
                                        viewModel: viewModel
                                    )
                                    .environmentObject(onboardingVM) // keep env for card if needed
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // ← added to fill the screen
            .background(
                LinearGradient(colors: [Color.purple, Color.black],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            // Location → upsert once, then refresh feed
            .onChange(of: locationManager.userLocation) { _, newLocation in
                guard let uid = onboardingVM.userId, !uid.isEmpty else {
                    print("[HomeView] Missing userId")
                    return
                }
                guard let loc = newLocation else {
                    print("[HomeView] Waiting for valid location…")
                    return
                }

                let lat = loc.coordinate.latitude
                let lng = loc.coordinate.longitude

                // ← added previously: write location once per appearance/session
                if !didUpsertLocation {
                    Task {
                        do {
                            try await FirebaseManager.shared.upsertLocation(uid: uid, lat: lat, lng: lng)
                            didUpsertLocation = true
                            print("[HomeView] Upserted location for \(uid)")
                        } catch {
                            print("[HomeView] upsertLocation failed: \(error)")
                        }
                    }
                }

                print("[HomeView] Location ready. Fetching with uid: \(uid), lat: \(lat), lng: \(lng)")
                viewModel.fetchDiscoveryFeed(uid: uid, lat: lat, lng: lng)
            }
            .onAppear {
                // Kick off permissions / first fetch if desired
                locationManager.requestLocation()
            }
        }
    }
}

// MARK: - DiscoveryMatchCard (reads onboardingVM from the environment)
struct DiscoveryMatchCard: View {
    let match: DiscoveryMatch
    @ObservedObject var viewModel: DiscoveryFeedViewModel
    @EnvironmentObject var onboardingVM: OnboardingViewModel   // ← read from env

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // ✅ Updated image block for non-optional photoUrl (String)
                if !match.photoUrl.isEmpty, let url = URL(string: match.photoUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .opacity(0.2)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .opacity(0.2)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading) {
                    Text("\(match.firstName) \(match.lastName)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(match.major) • \(match.year)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                VStack {
                    Text("\(Int(round(match.matchPercent)))%")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Match")
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            // Orgs row — use non-optional array directly
            HStack {
                ForEach(match.orgs, id: \.self) { org in
                    Text(org)
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }
}

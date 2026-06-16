import SwiftUI
import Foundation

struct TabBarView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel

    @State private var selection: Int = 0

    // Derived: show the auth/onboarding gate while signed out OR not fully onboarded
    private var needsAuthGate: Bool {
        let uid = onboardingVM.userId ?? ""
        return uid.isEmpty || !onboardingVM.onboardingComplete
    }

    var body: some View {
        ZStack {
            if !needsAuthGate {
                TabBarContentView(selection: $selection)
                    .onAppear {
                        // Start listener only when fully onboarded
                        if let uid = onboardingVM.userId, !uid.isEmpty, onboardingVM.onboardingComplete {
                            onboardingVM.startUserListener()
                        }
                    }
                    .onDisappear { onboardingVM.stopUserListener() }
                    .navigationBarBackButtonHidden(true)
                    .toolbar(.hidden, for: .navigationBar)
                    .onReceive(NotificationCenter.default.publisher(for: .switchToHomeTab)) { _ in
                        selection = 0
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .requestLogout)) { _ in
                        // VM will be reset by the logout button; this keeps TabBar quiet immediately
                        onboardingVM.stopUserListener()
                        selection = 0
                    }
            }
        }
        // Present the auth/onboarding stack whenever needed;
        // it cannot be swiped away until onboarding completes.
        .fullScreenCover(
            isPresented: Binding(
                get: { needsAuthGate },
                set: { _ in /* derived; no-op */ }
            )
        ) {
            GetStartedView()
                .environmentObject(onboardingVM)
                .interactiveDismissDisabled(true)
        }
    }
}

private struct TabBarContentView: View {
    @Binding var selection: Int

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            WavesRequestsView()
                .tabItem { Label("Waves", systemImage: "hand.wave.fill") }
                .tag(1)

            ChatsView()
                .tabItem { Label("Chats", systemImage: "message.fill") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Me", systemImage: "person.fill") }
                .tag(3)
        }
    }
}

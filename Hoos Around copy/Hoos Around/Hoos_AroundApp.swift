import SwiftUI
import Firebase
import FirebaseAppCheck

@main
struct HoosAroundApp: App {
    @StateObject private var onboardingVM = OnboardingViewModel()

    init() {
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif

        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            GetStartedView()
                .environmentObject(onboardingVM)
                .preferredColorScheme(.light)
        }
    }
}

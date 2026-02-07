import SwiftUI

@main
struct QuotieApp: App {
    @StateObject private var auth = AuthManager.shared

    @State private var hasSeenOnboarding: Bool =
        UserDefaults.standard.bool(forKey: OnboardingKeys.hasSeenOnboarding)

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    RootTabView()
                } else {
                    OnboardingFlowView {
                        hasSeenOnboarding = true
                        UserDefaults.standard.set(true, forKey: OnboardingKeys.hasSeenOnboarding)
                    }
                }
            }
            .environmentObject(auth)
            .task {
                await auth.start()
            }
        }
    }
}

enum OnboardingKeys {
    static let hasSeenOnboarding = "memmi.hasSeenOnboarding"
}

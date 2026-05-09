import SwiftUI
import UserNotifications

@main
struct QuotieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var auth = AuthManager.shared
    @AppStorage(AppAppearance.storageKey) private var appAppearanceRawValue: String = AppAppearance.system.rawValue

    @State private var hasSeenOnboarding: Bool =
        UserDefaults.standard.bool(forKey: OnboardingKeys.hasSeenOnboarding)

    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .system
    }

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
            .preferredColorScheme(appAppearance.colorScheme)
            .task {
                await auth.start()
            }
        }
    }
}

enum OnboardingKeys {
    static let hasSeenOnboarding = "memmi.hasSeenOnboarding"
}

// MARK: - App Delegate
// Wires up UNUserNotificationCenterDelegate so tapping a resurface
// notification deep-links into the right quote.

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when the user taps a notification (app in background/killed)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        MemmiNotifications.shared.handleNotificationResponse(response)
        completionHandler()
    }

    // Called when a notification arrives while the app is foregrounded
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(MemmiNotifications.shared.willPresentNotification(notification))
    }
}

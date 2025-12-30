
import SwiftUI

@main
struct QuotieApp: App {
    @State private var hasSeenOnboarding: Bool =
           UserDefaults.standard.bool(forKey: OnboardingKeys.hasSeenOnboarding)

       var body: some Scene {
           WindowGroup {
               if hasSeenOnboarding {
                   RootTabView()
               } else {
                   OnboardingFlowView {
                       hasSeenOnboarding = true
                       UserDefaults.standard.set(true, forKey: OnboardingKeys.hasSeenOnboarding)
                   }
               }
           }
       }
   }

   enum OnboardingKeys {
       static let hasSeenOnboarding = "memmi.hasSeenOnboarding"
   }


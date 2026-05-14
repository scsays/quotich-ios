import Foundation
import Combine
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private init() {}

    @Published var isReady: Bool = false
    @Published var isSignedIn: Bool = false

    func start() async {
        let client = SupabaseClientProvider.shared.client

        // If we already have a session, great.
        if (try? await client.auth.session) != nil {
            isSignedIn = true
            isReady = true
            return
        }

        // Otherwise sign in anonymously (requires it enabled in Supabase Auth settings)
        do {
            _ = try await client.auth.signInAnonymously()
            isSignedIn = true
        } catch {
            isSignedIn = false
            #if DEBUG
            print("Anonymous sign-in failed")
            #endif
        }

        isReady = true
    }
}

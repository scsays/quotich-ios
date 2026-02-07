import Foundation
import Supabase

final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()

    let client: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://ljyupdzfpwnyykgxvbqa.supabase.co")!
        let supabaseAnonKey = "sb_publishable_SHzYOj1wI75KO45cv6fwzw__JtpNpv2"
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)
    }
}

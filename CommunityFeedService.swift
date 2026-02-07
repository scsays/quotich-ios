import Foundation
import Supabase

final class CommunityFeedService {
    static let shared = CommunityFeedService()
    private init() {}

    enum Sort: String {
        case new
        case old
        case top      // most favorited
        case adds
    }

    // MARK: - RPC Params

    private struct FeedParams: Encodable {
        let p_limit: Int
        let p_offset: Int
        let p_sort: String
    }

    // MARK: - Fetch feed (paged)

    func fetchFeed(
        limit: Int = 30,
        offset: Int = 0,
        sort: Sort = .new
    ) async throws -> [CommunityFeedQuote] {

        let client = SupabaseClientProvider.shared.client
        let params = FeedParams(p_limit: limit, p_offset: offset, p_sort: sort.rawValue)

        // RPC: public.get_community_feed(p_limit int, p_offset int, p_sort text)
        let rows: [CommunityFeedQuote] = try await client
            .rpc("get_community_feed", params: params)
            .execute()
            .value

        return rows
    }

    // MARK: - Submit quote

    func submitQuote(text: String, author: String?, source: String?) async throws {
        let client = SupabaseClientProvider.shared.client

        // DB triggers handle: content_hash, status, created_at, created_by_user_id, etc.
        // We only insert the fields the user provides.
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = (author ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSource = (source ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            throw CommunityFeedError.invalidInput("Quote text can’t be empty.")
        }

        let payload: [String: AnyJSON] = [
            "text": .string(trimmedText),
            "author": .string(trimmedAuthor),
            "source": .string(trimmedSource)
        ]

        _ = try await client
            .from("community_quotes")
            .insert(payload)
            .execute()

        NotificationCenter.default.post(name: .communityFeedDidChange, object: nil)
    }

    // MARK: - Surprise Me

    func fetchRandomQuote() async throws -> CommunityFeedQuote {
        let client = SupabaseClientProvider.shared.client

        // RPC: public.get_random_community_quote()
        // IMPORTANT: your DB function must return the same columns as CommunityFeedQuote expects
        let rows: [CommunityFeedQuote] = try await client
            .rpc("get_random_community_quote")
            .execute()
            .value

        guard let first = rows.first else {
            throw CommunityFeedError.notFound("No active community quotes found.")
        }

        return first
    }
}

// MARK: - Errors

enum CommunityFeedError: LocalizedError {
    case invalidInput(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message): return message
        case .notFound(let message): return message
        }
    }
}

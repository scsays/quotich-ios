import Foundation

// MARK: - Shared model used by app and widget

struct SharedQuote: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String
    let author: String?
    let createdAt: Date
    let colorStyleRaw: String   // <- NEW: which PastelStyle (as a String)
}

// MARK: - Store for reading/writing the latest quote via App Group

struct SharedQuoteStore {
    // ⚠️ Must match your App Group in Signing & Capabilities
    private static let appGroupID = "group.com.QuotichApp.Quotich"
    private static let latestQuoteKey = "latestQuote"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func saveLatestQuote(_ quote: SharedQuote) {
        guard let defaults = defaults else {
            print("SharedQuoteStore: could not get UserDefaults for app group")
            return
        }

        do {
            let data = try JSONEncoder().encode(quote)
            defaults.set(data, forKey: latestQuoteKey)
        } catch {
            print("SharedQuoteStore: failed to encode quote: \(error)")
        }
    }

    static func loadLatestQuote() -> SharedQuote? {
        guard
            let defaults = defaults,
            let data = defaults.data(forKey: latestQuoteKey)
        else {
            return nil
        }

        do {
            return try JSONDecoder().decode(SharedQuote.self, from: data)
        } catch {
            print("SharedQuoteStore: failed to decode quote: \(error)")
            return nil
        }
    }
}

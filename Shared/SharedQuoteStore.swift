import Foundation

// MARK: - Shared model used by app and widget

struct SharedQuote: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String
    let author: String?
    let createdAt: Date
    let colorStyleRaw: String
}

// MARK: - SharedQuoteStore
// Supports BOTH:
// 1) "Latest quote" (UserDefaults) for fallback behavior
// 2) "All quotes" (quotes.json) so widgets can rotate across everything

struct SharedQuoteStore {

    // ✅ Single source of truth
    private static let appGroupID = SharedConfig.appGroupID
    private static let latestQuoteKey = "latestQuote"

    // MARK: - UserDefaults (latest quote)

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func saveLatestQuote(_ quote: SharedQuote) {
        guard let defaults = defaults else {
            #if DEBUG
            print("SharedQuoteStore: could not get UserDefaults for app group")
            #endif
            return
        }

        do {
            let data = try JSONEncoder().encode(quote)
            defaults.set(data, forKey: latestQuoteKey)
        } catch {
            #if DEBUG
            print("SharedQuoteStore: failed to encode latest quote")
            #endif
        }
    }

    static func loadLatestQuote() -> SharedQuote? {
        guard
            let defaults = defaults,
            let data = defaults.data(forKey: latestQuoteKey)
        else { return nil }

        do {
            return try JSONDecoder().decode(SharedQuote.self, from: data)
        } catch {
            #if DEBUG
            print("SharedQuoteStore: failed to decode latest quote")
            #endif
            return nil
        }
    }

    // MARK: - File-based store (all quotes)

    private static func quotesFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(SharedConfig.quotesFilename)
    }

    /// A lightweight “shape” of your app’s Quote that we can decode in the widget.
    /// Important: JSONDecoder will ignore extra fields that exist in the file.
    private struct QuoteStub: Codable {
        let id: UUID
        let text: String
        let author: String?
        let createdAt: Date?
        let colorStyle: String?
        let colorStyleRaw: String?

        enum CodingKeys: String, CodingKey {
            case id, text, author, createdAt, colorStyle, colorStyleRaw
        }
    }

    private struct StoredQuotesEnvelopeStub: Codable {
        let version: Int
        let quotes: [QuoteStub]
    }

    /// Loads ALL quotes from the shared quotes.json (the app writes an envelope).
    static func loadAllQuotes() -> [SharedQuote] {
        guard let url = quotesFileURL() else {
            #if DEBUG
            print("SharedQuoteStore: could not resolve app group container URL")
            #endif
            return []
        }

        guard let data = try? Data(contentsOf: url) else {
            // No file yet is totally fine
            return []
        }

        let decoder = JSONDecoder()

        // 1) Current format: envelope { version, quotes: [Quote] }
        if let envelope = try? decoder.decode(StoredQuotesEnvelopeStub.self, from: data) {
            return envelope.quotes.compactMap { stub in
                mapStubToSharedQuote(stub)
            }
        }

        // 2) Legacy format: [Quote]
        if let stubs = try? decoder.decode([QuoteStub].self, from: data) {
            return stubs.compactMap { stub in
                mapStubToSharedQuote(stub)
            }
        }

        // 3) Very old format: [SharedQuote]
        if let shared = try? decoder.decode([SharedQuote].self, from: data) {
            return shared
        }

        #if DEBUG
        print("SharedQuoteStore: could not decode quotes.json as envelope or array")
        #endif
        return []
    }

    private static func mapStubToSharedQuote(_ stub: QuoteStub) -> SharedQuote? {
        let text = stub.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        let authorTrimmed = (stub.author ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let authorOut = authorTrimmed.isEmpty ? nil : authorTrimmed

        // Your app likely encodes PastelStyle under `colorStyle` (rawValue).
        let style = (stub.colorStyleRaw ?? stub.colorStyle ?? "mint")
        let created = stub.createdAt ?? Date()

        return SharedQuote(
            id: stub.id,
            text: text,
            author: authorOut,
            createdAt: created,
            colorStyleRaw: style
        )
    }

    /// Deterministic daily quote from ALL quotes.
    /// - Stable for the whole day
    /// - Changes the next day (local time)
    static func loadQuoteForToday() -> SharedQuote? {
        let quotes = loadAllQuotes()
        guard !quotes.isEmpty else { return nil }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let dayNumber = Int(startOfDay.timeIntervalSince1970 / 86_400)

        let idx = abs(dayNumber) % quotes.count
        return quotes[idx]
    }

    /// Convenience: prefer daily quote from all quotes,
    /// fall back to latestQuote if needed.
    static func loadWidgetQuote() -> SharedQuote? {
        loadQuoteForToday() ?? loadLatestQuote()
    }
}

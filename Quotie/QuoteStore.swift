import Foundation
import Combine
import WidgetKit   // <- needed for WidgetCenter

// MARK: - Versioned storage envelope for saved quotes

private struct StoredQuotesEnvelope: Codable {
    let version: Int        // storage format version
    let quotes: [Quote]
}
// Bump this if you ever change how quotes are stored on disk
let currentQuotesStorageVersion = 1

class QuoteStore: ObservableObject {
    @Published var quotes: [Quote] {
        didSet {
            saveQuotes()   // <- now matches the function name below
        }
    }

    init() {
        self.quotes = Self.loadQuotes()
    }
    
    @Published var hungerLevel: Int = 0
    @Published var lastFedDate: Date = .now

    func applyDailyHungerDecay() {
        let calendar = Calendar.current
        let daysPassed = calendar.dateComponents(
            [.day],
            from: lastFedDate,
            to: Date()
        ).day ?? 0

        if daysPassed > 0 {
            hungerLevel = max(hungerLevel - daysPassed, 0)
            lastFedDate = Date()
        }
    }
    func feedMonster(with quote: Quote) {
        let bonus = quote.text.count >= 77 ? 2 : 1
        hungerLevel = min(hungerLevel + bonus, 5)
        lastFedDate = Date()
    }


    // MARK: - Public API
    func addQuote(
        text: String,
        author: String,
        source: String,
        colorStyle: PastelStyle,
        fontStyle: FontStyle
    ) {
        let newQuote = Quote(
            text: text,
            author: author,
            source: source,
            isFavorite: false,
            colorStyle: colorStyle,
            fontStyle: fontStyle
        )
        quotes.append(newQuote)
        updateWidgetQuoteOfTheDay()

        // Feed the monster whenever a quote is added
        feedMonster(with: newQuote)
    }


    func toggleFavorite(_ quote: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == quote.id }) {
            quotes[index].isFavorite.toggle()
        }
    }

    func delete(_ quote: Quote) {
        quotes.removeAll { $0.id == quote.id }
        updateWidgetQuoteOfTheDay()
    }

    func resurfaceQuote() -> Quote? {
        let favorites = quotes.filter { $0.isFavorite }
        let pool = favorites.isEmpty ? quotes : favorites

        guard !pool.isEmpty else { return nil }

        let chosen = pool.randomElement()!

        if let index = quotes.firstIndex(where: { $0.id == chosen.id }) {
            quotes[index].timesResurfaced += 1
            quotes[index].lastResurfacedAt = Date()
            return quotes[index]
        } else {
            return chosen
        }
    }
    
    func updateQuote(id: UUID, text: String, author: String, source: String) {
        guard let idx = quotes.firstIndex(where: { $0.id == id }) else { return }

        let old = quotes[idx]

        let updated = Quote(
            id: old.id,
            text: text,
            author: author,
            source: source,
            isFavorite: old.isFavorite,
            colorStyle: old.colorStyle,
            fontStyle: old.fontStyle
        )

        quotes[idx] = updated
        // No need to call saveQuotes() explicitly because didSet on `quotes` already saves.
        updateWidgetQuoteOfTheDay()
    }

    func update(_ updated: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == updated.id }) {
            quotes[index] = updated
        }
    }

    // MARK: - Persistence

    /// Shared location for app + widget
    private static func sharedFileURL() -> URL? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: sharedAppGroupID)
        else {
            return nil
        }
        return containerURL.appendingPathComponent(sharedQuotesFilename)
    }

    private static func loadQuotes() -> [Quote] {
        guard let url = sharedFileURL(),
              let data = try? Data(contentsOf: url)
        else {
            return sampleQuotes
        }

        let decoder = JSONDecoder()

        // 1) New format: envelope { version, quotes }
        if let envelope = try? decoder.decode(StoredQuotesEnvelope.self, from: data) {
            return envelope.quotes
        }

        // 2) Legacy format: plain array of Quote
        if let legacyQuotes = try? decoder.decode([Quote].self, from: data) {
            return legacyQuotes
        }

        // 3) If both fail, fall back to built-in samples
        return sampleQuotes
    }

    private func saveQuotes() {
        guard let url = Self.sharedFileURL() else { return }

        do {
            let envelope = StoredQuotesEnvelope(
                version: currentQuotesStorageVersion,
                quotes: quotes
            )

            let data = try JSONEncoder().encode(envelope)
            try data.write(to: url, options: .atomic)

            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        } catch {
            print("Failed to save quotes for widget: \(error)")
        }
    }
}
extension QuoteStore {

    /// Deterministic "random" quote for a given day.
    func quoteFor(date: Date = Date()) -> Quote? {
        guard !quotes.isEmpty else { return nil }

        // Day-of-year → stable index for that day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        let index = dayOfYear % quotes.count
        return quotes[index]
    }

    /// Push today's quote to the widget
    func updateWidgetQuoteOfTheDay() {
        guard let quote = quoteFor() else { return }

        let shared = SharedQuote(
            id: quote.id,
            text: quote.text,
            author: quote.author.isEmpty ? nil : quote.author,
            createdAt: Date(),
            colorStyleRaw: quote.colorStyle.rawValue
        )

        SharedQuoteStore.saveLatestQuote(shared)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

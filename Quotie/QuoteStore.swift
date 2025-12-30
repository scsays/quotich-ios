import Foundation
import Combine
import WidgetKit   // needed for WidgetCenter

// MARK: - Versioned storage envelope for saved quotes

private struct StoredQuotesEnvelope: Codable {
    let version: Int
    let quotes: [Quote]
}

// Bump this if you ever change how quotes are stored on disk
let currentQuotesStorageVersion = 1

final class QuoteStore: ObservableObject {

    // MARK: - UserDefaults Keys (hunger persistence)
    private let hungerKey = "memmi.hungerLevel"
    private let lastFedKey = "memmi.lastFedDate"

    // MARK: - Quotes
    @Published var quotes: [Quote] {
        didSet {
            saveQuotes()
        }
    }

    // MARK: - Hunger / Monster State (persisted)
    @Published var hungerLevel: Int {
        didSet {
            guard hungerLevel != oldValue else { return }
            persistHungerState()
            MemmiNotifications.shared.refreshHungryNudge(hungerLevel: hungerLevel)
        }
    }

    @Published var lastFedDate: Date {
        didSet {
            persistHungerState()
        }
    }

    @Published var lastAddedQuoteID: UUID?

    // MARK: - Init
    init() {
        self.quotes = Self.loadQuotes()

        let defaults = UserDefaults.standard
        let storedHunger = defaults.integer(forKey: hungerKey)

        // Date may not exist yet on first launch
        let storedLastFed = defaults.object(forKey: lastFedKey) as? Date ?? Date()

        self.hungerLevel = storedHunger
        self.lastFedDate = storedLastFed

        // Apply decay after loading persisted values so state is correct
        applyDailyHungerDecay()
    }

    // MARK: - Hunger Logic

    func applyDailyHungerDecay() {
        let calendar = Calendar.current
        let daysPassed = calendar.dateComponents([.day], from: lastFedDate, to: Date()).day ?? 0

        guard daysPassed > 0 else { return }

        hungerLevel = max(hungerLevel - daysPassed, 0)
        lastFedDate = Date()
    }

    func feedMonster(with quote: Quote) {
        let bonus = quote.text.count >= 77 ? 2 : 1
        hungerLevel = min(hungerLevel + bonus, 5)
        lastFedDate = Date()
    }

    // MARK: - Public API

    func updateMemmiReaction(for quoteID: UUID, reaction: String) {
        guard let index = quotes.firstIndex(where: { $0.id == quoteID }) else { return }
        quotes[index].memmiReaction = reaction
    }

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
        lastAddedQuoteID = newQuote.id

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
        updateWidgetQuoteOfTheDay()
    }

    func update(_ updated: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == updated.id }) {
            quotes[index] = updated
        }
    }

    // MARK: - Hunger Persistence

    private func persistHungerState() {
        let defaults = UserDefaults.standard
        defaults.set(hungerLevel, forKey: hungerKey)
        defaults.set(lastFedDate, forKey: lastFedKey)
    }

    // MARK: - Quote Persistence (App Group: app + widget)

    /// Shared location for app + widget
    private static func sharedFileURL() -> URL? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedConfig.appGroupID)
        else {
            return nil
        }
        return containerURL.appendingPathComponent(SharedConfig.quotesFilename)
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

// MARK: - Widget Helpers
extension QuoteStore {

    /// Deterministic "random" quote for a given day.
    func quoteFor(date: Date = Date()) -> Quote? {
        guard !quotes.isEmpty else { return nil }

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

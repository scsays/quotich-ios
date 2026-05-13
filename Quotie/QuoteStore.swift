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

    // MARK: - Devour Log (stats)
    private let devourLogKey = "memmi.devourLog.v1"

    @Published private(set) var devourLog: [DevourEvent] = [] {
        didSet { persistDevourLog() }
    }

    // MARK: - Quotes
    @Published var quotes: [Quote] {
        didSet { saveQuotes() }
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
        didSet { persistHungerState() }
    }

    @Published var lastAddedQuoteID: UUID?

    // MARK: - Init
    init() {
        self.quotes = Self.loadQuotes()

        let defaults = UserDefaults.standard
        let storedHunger = defaults.integer(forKey: hungerKey)
        let storedLastFed = defaults.object(forKey: lastFedKey) as? Date ?? Date()

        self.hungerLevel = storedHunger
        self.lastFedDate = storedLastFed
        self.devourLog = Self.loadDevourLog(key: devourLogKey)

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

        // ✅ Log a devour event for stats
        let normalized = quote.source.trimmingCharacters(in: .whitespacesAndNewlines)
        let event = DevourEvent(
            quoteID: quote.id,
            source: normalized.isEmpty ? "Unknown" : normalized
        )
        devourLog.append(event)
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
            fontStyle: fontStyle,
            memmiReaction: nil,
              createdAt: Date()
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

    func majorityFontStyle(default fallback: FontStyle = .rounded) -> FontStyle {
        guard !quotes.isEmpty else { return fallback }

        let counts = Dictionary(grouping: quotes, by: \.fontStyle)
            .mapValues { $0.count }

        return FontStyle.allCases.max { lhs, rhs in
            counts[lhs, default: 0] < counts[rhs, default: 0]
        } ?? fallback
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
            timesResurfaced: old.timesResurfaced,
            lastResurfacedAt: old.lastResurfacedAt,
            fontStyle: old.fontStyle,
            memmiReaction: old.memmiReaction,
            createdAt: old.createdAt
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

    // MARK: - Devour Log Persistence

    private static func loadDevourLog(key: String) -> [DevourEvent] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: key) else { return [] }

        do {
            return try JSONDecoder().decode([DevourEvent].self, from: data)
        } catch {
            #if DEBUG
            print("Failed to decode devour log")
            #endif
            return []
        }
    }

    private func persistDevourLog() {
        let defaults = UserDefaults.standard
        do {
            let data = try JSONEncoder().encode(devourLog)
            defaults.set(data, forKey: devourLogKey)
        } catch {
            #if DEBUG
            print("Failed to encode devour log")
            #endif
        }
    }

    // MARK: - Quote Persistence (App Group: app + widget)

    /// Shared location for app + widget
    private static func sharedFileURL() -> URL? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedConfig.appGroupID)
        else { return nil }

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
            try data.write(
                to: url,
                options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
            )

            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        } catch {
            #if DEBUG
            print("Failed to save quotes for widget")
            #endif
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
extension QuoteStore {

    private func quotesAddedInLast7Days(from now: Date = Date()) -> [Quote] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        return quotes.filter { $0.createdAt >= cutoff }
    }

    private func devoursInLast7Days(from now: Date = Date()) -> [DevourEvent] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        return devourLog.filter { $0.date >= cutoff }
    }

    private var statEvents: [DevourEvent] {
        guard !devourLog.isEmpty else {
            return quotes.map { quote in
                DevourEvent(
                    quoteID: quote.id,
                    source: quote.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown" : quote.source,
                    date: quote.createdAt
                )
            }
        }

        return devourLog
    }

    func devoursThisWeekCount() -> Int {
        let recentDevours = devoursInLast7Days()
        return recentDevours.isEmpty ? quotesAddedInLast7Days().count : recentDevours.count
    }

    func devoursAllTimeCount() -> Int {
        quotes.count
    }

    func favoriteQuotesCount() -> Int {
        quotes.filter(\.isFavorite).count
    }

    func mostDevoursInAWeekCount() -> Int {
        let calendar = Calendar.current
        let events = statEvents.filter { $0.date != .distantPast }
        guard !events.isEmpty else { return quotes.count }

        let grouped = Dictionary(grouping: events) { event in
            calendar.dateInterval(of: .weekOfYear, for: event.date)?.start ?? event.date
        }

        return grouped.values.map(\.count).max() ?? 0
    }

    func topSourceLast7Days() -> String? {
        let recentDevours = devoursInLast7Days()
        if !recentDevours.isEmpty {
            return topSource(from: recentDevours.map(\.source))
        }
        return nil
    }

    func topSourceAllTime() -> String? {
        guard !devourLog.isEmpty else { return nil }
        return topSource(from: devourLog.map(\.source))
    }

    private func topSource(from sources: [String]) -> String? {
        var counts: [String: Int] = [:]
        for source in sources {
            let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.isEmpty ? "Unknown" : trimmed
            counts[key, default: 0] += 1
        }

        return counts.sorted { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending }
            return lhs.value > rhs.value
        }.first?.key
    }

    /// Quotes added in the last 7 days (used for mood generation)
    func weeklyDevouredQuoteTexts() -> [String] {
        quotesAddedInLast7Days()
            .sorted(by: { $0.createdAt < $1.createdAt })
            .map { $0.text }
    }
}

// MARK: - Smart Resurface for Notifications
extension QuoteStore {

    /// Picks the best quote to resurface and schedules tomorrow's 9 AM notification.
    /// Call this on app launch (onAppear) or after adding a new quote.
    /// MemmiNotifications will silently skip if already scheduled today.
    func scheduleResurfaceNotificationIfNeeded() {
        guard MemmiNotifications.notificationsEnabled else { return }
        guard !quotes.isEmpty else { return }

        let frequency = MemmiNotifications.favoriteResurfaceFrequencyPerDay
        let pickedQuotes = pickResurfaceCandidates(count: frequency)
        guard !pickedQuotes.isEmpty else { return }

        // Mark as resurfaced now so the algorithm doesn't repeat it
        for picked in pickedQuotes {
            if let idx = quotes.firstIndex(where: { $0.id == picked.id }) {
                quotes[idx].timesResurfaced += 1
                quotes[idx].lastResurfacedAt = Date()
            }
        }

        MemmiNotifications.shared.scheduleResurfaceNotifications(pickedQuotes)
    }

    private func pickResurfaceCandidates(count: Int) -> [Quote] {
        var selected: [Quote] = []
        var excluded = Set<UUID>()

        for _ in 0..<max(1, count) {
            guard let candidate = pickResurfaceCandidate(excluding: excluded) else { break }
            selected.append(candidate)
            excluded.insert(candidate.id)
        }

        return selected
    }

    /// Smart quote selection:
    ///   - 50% chance to draw from favorites pool when favorites exist
    ///   - Priority 1: quotes never surfaced before
    ///   - Priority 2: quotes not resurfaced in last 7 days, oldest first
    ///   - Fallback: least recently resurfaced in pool
    private func pickResurfaceCandidate(excluding excludedIDs: Set<UUID> = []) -> Quote? {
        let favorites = quotes.filter { $0.isFavorite }
        let preferredPool = favorites.isEmpty ? quotes : favorites
        let pool = preferredPool.filter { !excludedIDs.contains($0.id) }

        if pool.isEmpty, !favorites.isEmpty {
            return quotes.filter { !excludedIDs.contains($0.id) }
                .sorted { ($0.lastResurfacedAt ?? .distantPast) < ($1.lastResurfacedAt ?? .distantPast) }
                .first
        }

        // Priority 1: never resurfaced
        let virgin = pool.filter { $0.lastResurfacedAt == nil }
        if !virgin.isEmpty { return virgin.randomElement() }

        // Priority 2: stale (not resurfaced in 7+ days)
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let stale  = pool
            .filter  { ($0.lastResurfacedAt ?? .distantPast) < cutoff }
            .sorted  { ($0.lastResurfacedAt ?? .distantPast) < ($1.lastResurfacedAt ?? .distantPast) }
        if !stale.isEmpty { return stale.first }

        // Fallback: least recently resurfaced overall
        return pool.sorted { ($0.lastResurfacedAt ?? .distantPast) < ($1.lastResurfacedAt ?? .distantPast) }.first
    }
}

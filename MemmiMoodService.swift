import Foundation
import Combine

@MainActor
final class MemmiMoodService: ObservableObject {

    @Published private(set) var mood: String = "Quietly Reflective"
    @Published private(set) var isLoading: Bool = false

    // Cache so you don’t re-generate mood constantly.
    // v2 intentionally resets the old count-based cache.
    private let cacheKey = "memmi.mood.cache.v2"
    private let cacheDateKey = "memmi.mood.cacheDate.v2"

    private let endpointPlistKey = "MEMMI_MOOD_ENDPOINT"

    struct MoodResponse: Codable {
        let mood: String
    }

    func loadCachedMoodIfValid() {
        let defaults = UserDefaults.standard
        guard
            let cached = defaults.string(forKey: cacheKey),
            let date = defaults.object(forKey: cacheDateKey) as? Date
        else { return }

        // reuse for 12 hours
        if Date().timeIntervalSince(date) < 12 * 60 * 60 {
            self.mood = cached
        }
    }

    func refreshMood(using weeklyQuotes: [String]) async {
        let localMood = localMood(forWeeklyQuotes: weeklyQuotes)
        mood = localMood

        guard !weeklyQuotes.isEmpty else {
            cache(localMood)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let newMood = try await fetchMoodFromYourBackend(weeklyQuotes: weeklyQuotes)
            mood = newMood
            cache(newMood)
        } catch {
            // Fail soft with the content-based local classifier so the card
            // still reflects what Memmi has been fed, even without backend mood generation.
            mood = localMood
            cache(localMood)
            print("Mood generation fell back locally: \(error)")
        }
    }

    private func cache(_ mood: String) {
        let defaults = UserDefaults.standard
        defaults.set(mood, forKey: cacheKey)
        defaults.set(Date(), forKey: cacheDateKey)
    }

    private func fetchMoodFromYourBackend(weeklyQuotes: [String]) async throws -> String {
        guard let url = moodEndpointURL() else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["quotes": weeklyQuotes]
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(MoodResponse.self, from: data)
        let raw = decoded.mood.trimmingCharacters(in: .whitespacesAndNewlines)

        // Force “two words” lightly (backend already tries)
        let parts = raw.split(separator: " ").prefix(2)
        let twoWord = parts.joined(separator: " ")
        return twoWord.isEmpty ? "Quietly Reflective" : twoWord
    }

    private func moodEndpointURL() -> URL? {
        let plistValue = Bundle.main.object(forInfoDictionaryKey: endpointPlistKey) as? String
        let trimmed = (plistValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return nil
        }

        guard let url = URL(string: trimmed) else { return nil }

#if DEBUG
        return url
#else
        guard url.scheme?.lowercased() == "https" else { return nil }
        return url
#endif
    }

    private func localMood(forWeeklyQuotes quotes: [String]) -> String {
        let combined = quotes
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        guard !combined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Quietly Hungry"
        }

        let scoredThemes: [(theme: MoodTheme, score: Int)] = MoodTheme.allCases.map { theme in
            (theme, theme.score(in: combined))
        }

        if let winner = scoredThemes
            .filter({ $0.score > 0 })
            .sorted(by: { lhs, rhs in
                if lhs.score == rhs.score { return lhs.theme.priority < rhs.theme.priority }
                return lhs.score > rhs.score
            })
            .first {
            return winner.theme.moodName
        }

        return "Quietly Reflective"
    }
}

private enum MoodTheme: CaseIterable {
    case introspective
    case motivational
    case melancholic
    case considerate
    case grateful
    case romantic
    case resilient
    case calm
    case curious

    var moodName: String {
        switch self {
        case .introspective: return "Deeply Reflective"
        case .motivational:  return "Brightly Driven"
        case .melancholic:   return "Softly Melancholy"
        case .considerate:   return "Tenderly Considerate"
        case .grateful:      return "Warmly Grateful"
        case .romantic:      return "Lovingly Open"
        case .resilient:     return "Quietly Brave"
        case .calm:          return "Calmly Grounded"
        case .curious:       return "Curiously Searching"
        }
    }

    var priority: Int {
        switch self {
        case .melancholic:   return 0
        case .introspective: return 1
        case .resilient:     return 2
        case .considerate:   return 3
        case .motivational:  return 4
        case .romantic:      return 5
        case .grateful:      return 6
        case .calm:          return 7
        case .curious:       return 8
        }
    }

    private var keywords: [String] {
        switch self {
        case .introspective:
            return ["meaning", "truth", "self", "soul", "become", "becoming", "remember", "memory", "inside", "within", "understand", "attention", "story", "identity", "question", "reflection", "aware", "awareness"]
        case .motivational:
            return ["begin", "start", "rise", "go", "keep", "try", "courage", "brave", "build", "create", "change", "possible", "power", "win", "grow", "growth", "dream", "forward", "better", "strong"]
        case .melancholic:
            return ["grief", "loss", "sad", "sorrow", "hurt", "wound", "broken", "pain", "alone", "lonely", "dark", "ache", "cry", "tears", "missing", "empty", "heavy", "end", "goodbye"]
        case .considerate:
            return ["kind", "kindness", "gentle", "soft", "care", "compassion", "mercy", "listen", "understand", "forgive", "forgiveness", "human", "tender", "help", "hold", "space", "together"]
        case .grateful:
            return ["gratitude", "grateful", "thanks", "thankful", "blessing", "blessings", "gift", "enough", "abundance", "joy", "beautiful", "wonder", "appreciate", "appreciation"]
        case .romantic:
            return ["love", "lover", "heart", "beloved", "kiss", "desire", "devotion", "romance", "together", "intimacy", "adore", "affection", "passion"]
        case .resilient:
            return ["survive", "surviving", "endure", "heal", "healing", "recover", "stronger", "resilient", "still", "again", "through", "overcome", "scar", "carry"]
        case .calm:
            return ["peace", "peaceful", "stillness", "still", "breathe", "breath", "rest", "quiet", "slow", "present", "presence", "ease", "ground", "grounded", "patience"]
        case .curious:
            return ["why", "wonder", "curious", "mystery", "seek", "search", "learn", "discover", "question", "open", "unknown", "explore"]
        }
    }

    func score(in text: String) -> Int {
        keywords.reduce(0) { partial, keyword in
            partial + occurrences(of: keyword, in: text)
        }
    }

    private func occurrences(of keyword: String, in text: String) -> Int {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: keyword) + "\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.numberOfMatches(in: text, range: range)
    }
}

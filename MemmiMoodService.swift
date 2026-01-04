import Foundation
import Combine

@MainActor
final class MemmiMoodService: ObservableObject {

    @Published private(set) var mood: String = "Curiously Content"
    @Published private(set) var isLoading: Bool = false

    // Cache so you don’t re-generate mood constantly
    private let cacheKey = "memmi.mood.cache.v1"
    private let cacheDateKey = "memmi.mood.cacheDate.v1"

    // Info.plist key you’ll add in the next step
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
        guard !weeklyQuotes.isEmpty else {
            mood = "Quietly Hungry"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let newMood = try await fetchMoodFromYourBackend(weeklyQuotes: weeklyQuotes)
            mood = newMood

            let defaults = UserDefaults.standard
            defaults.set(newMood, forKey: cacheKey)
            defaults.set(Date(), forKey: cacheDateKey)
        } catch {
            // Fail soft — keep last mood
            print("Mood generation failed: \(error)")
        }
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
        return twoWord.isEmpty ? "Mysteriously Vibing" : twoWord
    }

    private func moodEndpointURL() -> URL? {
        // Reads from Info.plist:
        // MEMMI_MOOD_ENDPOINT = "https://your-domain.vercel.app/api/memmi-mood"
        // or for local dev:
        // MEMMI_MOOD_ENDPOINT = "http://192.168.1.123:3000/api/memmi-mood"
        let plistValue = Bundle.main.object(forInfoDictionaryKey: endpointPlistKey) as? String
        let trimmed = (plistValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            // Fallback: keeps you from crashing if you forget the plist key
            return URL(string: "https://YOUR_DOMAIN_HERE/api/memmi-mood")
        }

        return URL(string: trimmed)
    }
}

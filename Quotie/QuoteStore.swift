import Foundation
import Combine

class QuoteStore: ObservableObject {
    @Published var quotes: [Quote] {
        didSet {
            saveQuotes()
        }
    }
    
    init() {
        self.quotes = Self.loadQuotes()
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
    }
    
    func toggleFavorite(_ quote: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == quote.id }) {
            quotes[index].isFavorite.toggle()
        }
    }
    
    func delete(_ quote: Quote) {
        quotes.removeAll { $0.id == quote.id }
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
    
    
    func update(_ updated: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == updated.id }) {
            quotes[index] = updated
        }
    }
    
    // MARK: - Persistence
    
    private static let appGroupID = "group.Quotie-Team.Quotie"
    
    private static func fileURL() -> URL {
        // Prefer the shared App Group container so widgets can see the data
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupID
        ) {
            return container.appendingPathComponent("quotes.json")
        }
        
        // Fallback to documents directory if the group isn't available for some reason
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("quotes.json")
    }
    
    private static func loadQuotes() -> [Quote] {
        let url = fileURL()
        
        guard let data = try? Data(contentsOf: url) else {
            return sampleQuotes
        }
        
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([Quote].self, from: data) {
            return decoded
        } else {
            return sampleQuotes
        }
    }
    
    private func saveQuotes() {
        let url = Self.fileURL()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(quotes)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Failed to save quotes:", error)
        }
    }
}

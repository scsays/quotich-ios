import Foundation

// MARK: - Model used by both app & widget

enum PastelStyle: String, Codable, CaseIterable {
    case mint
    case blush
    case lilac
    case sky
    case peach
    case butter
}

enum FontStyle: String, Codable, CaseIterable {
    case standard
    case serif
    case rounded
}

struct Quote: Identifiable, Codable {
    var id: UUID
    let text: String
    let author: String
    let source: String
    var isFavorite: Bool
    var colorStyle: PastelStyle
    var timesResurfaced: Int
    var lastResurfacedAt: Date?
    var fontStyle: FontStyle
    var memmiReaction: String?


    init(
        id: UUID = UUID(),
        text: String,
        author: String,
        source: String,
        isFavorite: Bool = false,
        colorStyle: PastelStyle = .mint,
        timesResurfaced: Int = 0,
        lastResurfacedAt: Date? = nil,
        fontStyle: FontStyle = .rounded
    ) {
        self.id = id
        self.text = text
        self.author = author
        self.source = source
        self.isFavorite = isFavorite
        self.colorStyle = colorStyle
        self.timesResurfaced = timesResurfaced
        self.lastResurfacedAt = lastResurfacedAt
        self.fontStyle = fontStyle
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, author, source, isFavorite, colorStyle, timesResurfaced, lastResurfacedAt, fontStyle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        author = try container.decode(String.self, forKey: .author)
        source = try container.decode(String.self, forKey: .source)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        colorStyle = try container.decodeIfPresent(PastelStyle.self, forKey: .colorStyle) ?? .mint
        timesResurfaced = try container.decodeIfPresent(Int.self, forKey: .timesResurfaced) ?? 0
        lastResurfacedAt = try container.decodeIfPresent(Date.self, forKey: .lastResurfacedAt)
        fontStyle = try container.decodeIfPresent(FontStyle.self, forKey: .fontStyle) ?? .rounded
    }
    let sampleQuotes: [Quote] = []

}

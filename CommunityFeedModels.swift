import Foundation

struct CommunityFeedQuote: Identifiable, Decodable, Equatable {
    let id: UUID
    let text: String
    let author: String?
    let source: String?
    let createdAt: Date
    let createdByUserId: UUID?
    let favoritesCount: Int
    let addsCount: Int
    let isFavorited: Bool
    let isAdded: Bool

    enum CodingKeys: String, CodingKey {
        case id, text, author, source
        case createdAt = "created_at"
        case createdByUserId = "created_by_user_id"
        case favoritesCount = "favorites_count"
        case addsCount = "adds_count"
        case isFavorited = "is_favorited"
        case isAdded = "is_added"
    }
}
extension CommunityFeedQuote {
    var isForgeQATestQuote: Bool {
        author == "Forge test" || text.hasPrefix("TEST QUOTE — community feed cross-device check")
    }

    func asLocalQuote() -> Quote {
        Quote(
            id: id,
            text: text,
            author: author ?? "",
            source: source ?? "",
            isFavorite: isFavorited,
            colorStyle: .lilac,
            timesResurfaced: 0,
            lastResurfacedAt: nil,
            fontStyle: .rounded
        )
    }
}

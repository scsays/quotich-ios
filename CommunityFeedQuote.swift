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
}

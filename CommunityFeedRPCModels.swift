import Foundation

// MARK: - RPC Params

struct CommunityFeedRPCParams: Encodable, Sendable {
    let p_limit: Int
    let p_offset: Int
    let p_sort: String
}

// MARK: - Insert Model (for "Submit Quote")

struct CommunityQuoteInsert: Encodable, Sendable {
    let text: String
    let author: String?
    let source: String?
}

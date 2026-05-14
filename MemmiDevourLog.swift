import Foundation

struct DevourEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let quoteID: UUID
    let source: String
    let date: Date

    init(quoteID: UUID, source: String, date: Date = Date()) {
        self.id = UUID()
        self.quoteID = quoteID
        self.source = source
        self.date = date
    }
}

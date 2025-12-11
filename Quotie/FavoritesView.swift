import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var store: QuoteStore

    var body: some View {
        let favorites = store.quotes.filter { $0.isFavorite }
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(favorites) { quote in
                    MasonryQuoteCard(quote: quote) {
                        store.toggleFavorite(quote)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 110)
        }
    }
}

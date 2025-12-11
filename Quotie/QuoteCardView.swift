import SwiftUI

struct QuoteCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let quote: Quote
    let onToggleFavorite: () -> Void
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("“\(quote.text)”")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(
                    DesignSystem.primaryText(colorScheme)
                )
                .shadow(
                    color: colorScheme == .dark
                        ? Color.white.opacity(0.45)
                        : .clear,
                    radius: 4,
                    y: 2
                )

            if !quote.author.isEmpty {
                Text(quote.author)
                    .foregroundColor(
                        DesignSystem.secondaryText(colorScheme)
                    )
            }

            if !quote.source.isEmpty {
                Text(quote.source)
                    .foregroundColor(
                        DesignSystem.secondaryText(colorScheme)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    DesignSystem.cardGradient(
                        for: quote.colorStyle,
                        scheme: colorScheme
                    )
                )
        )
        .cardElevation(
            highlighted: isHighlighted,
            scheme: colorScheme
        )
    }
}


import SwiftUI

struct MasonryQuoteCard: View {
    @Environment(\.colorScheme) private var scheme
    let quote: Quote
    var onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("“\(quote.text)”")
                .font(font(for: quote.fontStyle))
                .foregroundStyle(DesignSystem.primaryText(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if !quote.author.isEmpty || !quote.source.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    if !quote.author.isEmpty {
                        Text(quote.author)
                            .font(.caption)
                            .foregroundStyle(DesignSystem.secondaryText(scheme))
                    }
                    if !quote.source.isEmpty {
                        Text(quote.source)
                            .font(.caption2)
                            .foregroundStyle(DesignSystem.secondaryText(scheme).opacity(0.9))
                    }
                }
            }

            HStack {
                Spacer()
                Button(action: onToggleFavorite) {
                    Image(systemName: quote.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(quote.isFavorite ? DesignSystem.monsterPurple : .secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DesignSystem.cardGradient(for: quote.colorStyle, scheme: scheme))
                .shadow(color: DesignSystem.cardShadow, radius: 10, y: 4)
        )
    }

    private func font(for style: FontStyle) -> Font {
        switch style {
        case .standard: return .system(.subheadline, design: .default)
        case .serif:    return .system(.subheadline, design: .serif)
        case .rounded:  return .system(.subheadline, design: .rounded)
        }
    }
}


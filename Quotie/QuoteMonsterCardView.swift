import SwiftUI

struct QuoteMonsterCardView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: QuoteStore
    let onFeedMe: () -> Void

    private var dailyQuote: Quote? { store.quoteFor() }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.72, green: 0.58, blue: 0.88),
                    Color(red: 0.55, green: 0.42, blue: 0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                // Header row
                HStack {
                    Text("Quote Monster")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.95))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.18)))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)

                QuoteMonsterView(mood: .happy)
                    .scaleEffect(1.3)
                    .padding(.top, 4)

                // Hunger meter card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hunger Meter")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))

                    ProgressView(value: min(Double(store.hungerLevel) / 5.0, 1.0))
                        .tint(.white)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.22), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 22)

                // Quote card
                VStack(spacing: 10) {
                    Text("Quotie’s Favorite Quote")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    if let quote = dailyQuote {
                        Text("“\(quote.text)”")
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)

                        if !quote.author.isEmpty {
                            Text("— \(quote.author)")
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    } else {
                        Text("No quotes yet. Feed me your first one.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 22)

                Spacer()

                // Bottom buttons
                HStack(spacing: 14) {
                    Button {
                        dismiss()
                        onFeedMe()
                    } label: {
                        Text("Feed Me")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.purple)

                    Button {
                        dismiss()
                    } label: {
                        Text("Not Now")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.95))
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 26)
            }
        }
    }
}

import WidgetKit
import SwiftUI

// MARK: - Helper: map colorStyleRaw -> gradient colors

private func colorsFor(styleRaw: String?) -> [Color] {
    switch styleRaw {
    case "mint":
        return [Color.mint.opacity(0.7), .white]
    case "blush":
        return [Color.pink.opacity(0.7), .white]
    case "lilac":
        return [Color.purple.opacity(0.6), .white]
    case "sky":
        return [Color.blue.opacity(0.5), .white]
    case "peach":
        return [Color.orange.opacity(0.6), .white]
    case "butter":
        return [Color.yellow.opacity(0.6), .white]
    default:
        // Fallback
        return [Color.blue.opacity(0.5), .white]
    }
}

// MARK: - Entry

struct QuoteOfTheDayEntry: TimelineEntry {
    let date: Date
    let quote: SharedQuote?
}

// MARK: - Provider

struct QuoteOfTheDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteOfTheDayEntry {
        let sample = SharedQuote(
            id: UUID(),
            text: "Your next favorite quote will show up here.",
            author: "Quotie",
            createdAt: Date(),
            colorStyleRaw: "mint"
        )
        return QuoteOfTheDayEntry(date: Date(), quote: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteOfTheDayEntry) -> Void) {
        let shared = SharedQuoteStore.loadLatestQuote()
        let entry = QuoteOfTheDayEntry(date: Date(), quote: shared)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteOfTheDayEntry>) -> Void) {
        let now = Date()
        let quote = SharedQuoteStore.loadLatestQuote()

        let entry = QuoteOfTheDayEntry(date: now, quote: quote)

        // Refresh shortly after midnight so it can change daily
        let calendar = Calendar.current
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        let refreshDate = calendar.date(byAdding: .minute, value: 5, to: startOfTomorrow)! // 12:05am

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - View

struct QuoteOfTheDayEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: QuoteOfTheDayEntry

    var body: some View {
        ZStack {

            if let q = entry.quote {
                VStack(alignment: .leading, spacing: 10) {

                    // Quote text (left aligned, uses more space, scales down if needed)
                    Text("“\(q.text)”")
                        .font(quoteFont)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(quoteLineLimit)
                        .minimumScaleFactor(0.75)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Author
                    let author = (q.author ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !author.isEmpty {
                        Text("— \(author)")
                            .font(authorFont)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No quote yet")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Open Quotich and pick a quote for your widget.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                }
                .padding(16)
            }
        }
    }

    private var quoteFont: Font {
        switch family {
        case .systemSmall:
            return .system(size: 17, weight: .semibold, design: .rounded)
        default: // .systemMedium
            return .system(size: 20, weight: .semibold, design: .rounded)
        }
    }

    private var authorFont: Font {
        switch family {
        case .systemSmall:
            return .system(size: 14, weight: .medium, design: .rounded)
        default:
            return .system(size: 15, weight: .medium, design: .rounded)
        }
    }

    private var quoteLineLimit: Int {
        switch family {
        case .systemSmall:
            return 5
        default: // .systemMedium
            return 6
        }
    }
}
// MARK: - Widget

struct QuoteOfTheDayWidget: Widget {
    let kind: String = "QuoteOfTheDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteOfTheDayProvider()) { entry in
            QuoteOfTheDayEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    let colors = colorsFor(styleRaw: entry.quote?.colorStyleRaw)
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Latest Quotie")
        .description("Shows your most recently selected quote.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}



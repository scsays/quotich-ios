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
        let shared = SharedQuoteStore.loadLatestQuote()
        let entry = QuoteOfTheDayEntry(date: Date(), quote: shared)

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(1800)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - View

struct QuoteOfTheDayEntryView: View {
    let entry: QuoteOfTheDayEntry

    var body: some View {
        ZStack {
            if let quote = entry.quote {
                VStack(alignment: .leading, spacing: 8) {
                    // Small label at the top
                    Text("Quotie")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .opacity(0.9)

                    // MAIN QUOTE TEXT – bigger, no autoshrink
                    Text("“\(quote.text)”")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)              // truncate instead of shrinking
                        .truncationMode(.tail)

                    if let author = quote.author, !author.isEmpty {
                        Text("— \(author)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .opacity(0.9)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .foregroundStyle(Color.white)
                .padding(16)
            } else {
                VStack(spacing: 6) {
                    Text("No quote yet")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("Open Quotich and tap “Use in Widget”.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .truncationMode(.tail)
                }
                .foregroundStyle(Color.white)
                .padding(16)
            }
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



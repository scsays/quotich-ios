import WidgetKit
import SwiftUI

// MARK: - Shared config

private let appGroupID = "group.Quotie-Team.Quotie"
private let widgetEnabledKey = "widgetDailyQuotesEnabled"

// MARK: - Timeline Entry

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote?
}

// MARK: - Provider

struct QuoteProvider: TimelineProvider {

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(
            date: Date(),
            quote: Quote(
                text: "Attention is the rarest and purest form of generosity.",
                author: "Simone Weil",
                source: "Book",
                isFavorite: true,
                colorStyle: .sky
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> ()) {
        let entry = loadEntryForToday()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> ()) {
        let entry = loadEntryForToday()

        // Refresh around next midnight
        let calendar = Calendar.current
        let nextMidnight = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? Date().addingTimeInterval(60 * 60 * 24)

        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    // MARK: - Data Loading

    private func loadEntryForToday() -> QuoteEntry {
        // Check the "daily quote enabled?" setting from the shared app group
        let enabled = UserDefaults(suiteName: appGroupID)?
            .bool(forKey: widgetEnabledKey) ?? true

        guard enabled else {
            // User turned off daily quotes → show neutral state
            return QuoteEntry(date: Date(), quote: nil)
        }

        let quotes = loadQuotesFromSharedFile()

        guard !quotes.isEmpty else {
            // No quotes saved yet
            return QuoteEntry(date: Date(), quote: nil)
        }

        // Pick a random quote from ALL quotes
        let random = quotes.randomElement()!
        return QuoteEntry(date: Date(), quote: random)
    }

    private func loadQuotesFromSharedFile() -> [Quote] {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return []
        }

        let fileURL = containerURL.appendingPathComponent("quotes.json")

        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        let decoder = JSONDecoder()
        // Use the same decoding behavior as the main app
        if let decoded = try? decoder.decode([Quote].self, from: data) {
            return decoded
        } else {
            return []
        }
    }
}

// MARK: - Widget View

import SwiftUI
import WidgetKit

struct QuoteWidgetEntryView: View {
    var entry: QuoteProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let quote = entry.quote {
            content(for: quote)
        } else {
            placeholder
        }
    }

    // MARK: - Quote Content

    @ViewBuilder
    private func content(for quote: Quote) -> some View {
        let gradient = gradientColors(for: quote.colorStyle)
        let radius   = cornerRadius

        ZStack {
            // Full-bleed gradient
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Text stack
            VStack(alignment: .leading, spacing: spacing) {
                // Bigger main quote text
                Text("“\(quote.text)”")
                    .font(quoteFont)                 // <- bumped sizes
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.55)        // allow scaling down a bit
                    .lineLimit(quoteLineLimit)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4)

                // Author (same sizes as before)
                Text(quote.author.isEmpty ? "Unknown" : quote.author)
                    .font(authorFont)
                    .fontWeight(.bold)
                    .opacity(0.92)

                if family != .systemSmall {
                    Text(quote.source)
                        .font(sourceFont)
                        .opacity(0.85)
                }
            }
            .foregroundColor(.white)
            .padding(padding)
        }
        // Match the widget’s rounded corners, then add a stroke border
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.40), lineWidth: 1.0)
        )
    }

    // MARK: - Placeholder

    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Text("Add quotes in Quotie 🔖")
                .foregroundColor(.secondary)
                .padding()
        }
    }

    // MARK: - Layout Values

    private var padding: CGFloat {
        switch family {
        case .systemSmall:  return 14
        case .systemMedium: return 20
        default:            return 24
        }
    }

    private var spacing: CGFloat {
        switch family {
        case .systemSmall:  return 6
        case .systemMedium: return 10
        default:            return 14
        }
    }

    private var cornerRadius: CGFloat {
        switch family {
        case .systemSmall:  return 18
        case .systemMedium: return 20
        default:            return 22
        }
    }

    // BIGGER quote font, same author/source fonts as before
    private var quoteFont: Font {
        switch family {
        case .systemSmall:
            return .system(size: 18, weight: .semibold, design: .rounded)
        case .systemMedium:
            return .system(size: 24, weight: .semibold, design: .rounded)
        default:
            return .system(size: 30, weight: .semibold, design: .rounded)
        }
    }

    private var authorFont: Font {
        switch family {
        case .systemSmall:
            return .system(size: 11, design: .rounded)
        case .systemMedium:
            return .system(size: 15, design: .rounded)
        default:
            return .system(size: 18, design: .rounded)
        }
    }

    private var sourceFont: Font {
        switch family {
        case .systemSmall:
            return .system(size: 10, design: .rounded)
        case .systemMedium:
            return .system(size: 13, design: .rounded)
        default:
            return .system(size: 15, design: .rounded)
        }
    }

    private var quoteLineLimit: Int {
        switch family {
        case .systemSmall:  return 4
        case .systemMedium: return 6
        default:            return 8
        }
    }

    // MARK: - Gradient Helper

    private func gradientColors(for style: PastelStyle) -> [Color] {
        switch style {
        case .mint:   return [Color.mint.opacity(0.9), Color.mint.opacity(0.6)]
        case .blush:  return [Color.pink.opacity(0.9), Color.pink.opacity(0.6)]
        case .lilac:  return [Color.purple.opacity(0.9), Color.purple.opacity(0.6)]
        case .sky:    return [Color.blue.opacity(0.9), Color.blue.opacity(0.6)]
        case .peach:  return [Color.orange.opacity(0.9), Color.orange.opacity(0.6)]
        case .butter: return [Color.yellow.opacity(0.9), Color.yellow.opacity(0.6)]
        }
    }
}

// MARK: - Widget Definition

struct QuotieWidget: Widget {
    let kind: String = "QuotieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quotie")
        .description("See a random quote from your collection each day.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

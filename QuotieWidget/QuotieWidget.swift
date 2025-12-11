import WidgetKit
import SwiftUI

// MARK: - Model
struct QuotieWidgetEntry: TimelineEntry {
    let date: Date
    let quote: String
    let author: String
}

struct QuoteOfDay {
    let text: String
    let author: String

    static let samples: [QuoteOfDay] = [
        .init(text: "There were times when you couldn’t fix what was broken with words, and this looked like one of those times.", author: "Auntie"),
        .init(text: "Attention is the rarest and purest form of generosity.", author: "Simone Weil"),
        .init(text: "Not all who wander are lost.", author: "Gandalf"),
        .init(text: "We live, we die. Somewhere along the way, if we’re lucky, we may find someone to help lighten the load.", author: "Alicia"),
        .init(text: "Courage, Bob, courage.", author: "Sergio St. Carlos"),
        .init(text: "You are only as durable as the thing you love most.", author: "Tim Keller"),
    ]

    // ✅ Production: changes once per day (stable for the day)
    static func pickForDay(_ date: Date) -> QuoteOfDay {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return samples[(day - 1) % samples.count]
    }

    // ✅ Debug/test: changes every few minutes so you can SEE it update
    static func pickForMinuteBucket(_ date: Date, bucketMinutes: Int) -> QuoteOfDay {
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minuteOfDay = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let bucket = max(1, bucketMinutes)
        let idx = (minuteOfDay / bucket) % samples.count
        return samples[idx]
    }
}

// MARK: - Provider
struct QuotieWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> QuotieWidgetEntry {
        .init(date: .now,
              quote: "Attention is the rarest and purest form of generosity.",
              author: "Simone Weil")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuotieWidgetEntry) -> Void) {
        let q = QuoteOfDay.samples.first!
        completion(.init(date: .now, quote: q.text, author: q.author))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuotieWidgetEntry>) -> Void) {
        let now = Date()

        #if DEBUG
        // ✅ Easy-to-test mode: rotate every 5 minutes
        let q = QuoteOfDay.pickForMinuteBucket(now, bucketMinutes: 5)
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(300)
        let entry = QuotieWidgetEntry(date: now, quote: q.text, author: q.author)
        completion(Timeline(entries: [entry], policy: .after(next)))
        #else
        // ✅ Production mode: refresh daily shortly after midnight
        let q = QuoteOfDay.pickForDay(now)
        let entry = QuotieWidgetEntry(date: now, quote: q.text, author: q.author)

        let next = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? Calendar.current.date(byAdding: .day, value: 1, to: now)!

        completion(Timeline(entries: [entry], policy: .after(next)))
        #endif
    }
}

// MARK: - View (fits text better, no "Quotie" label)
struct QuotieWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: QuotieWidgetEntry

    var body: some View {
        ZStack {
            // Subtle background so text stays readable.
            // Replace later with your app gradients if you want.
            LinearGradient(
                colors: [
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("“\(entry.quote)”")
                    .font(quoteFont(for: family))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(lineLimit(for: family))
                    .minimumScaleFactor(0.72)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                Text("— \(entry.author)")
                    .font(authorFont(for: family))
                    .opacity(0.9)
                    .lineLimit(1)
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            Color.clear // keeps iOS happy; background is in ZStack above
        }
    }

    private func quoteFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:  return .system(size: 16, design: .rounded)
        case .systemMedium: return .system(size: 18, design: .rounded)
        case .systemLarge:  return .system(size: 22, design: .rounded)
        default:            return .system(size: 18, design: .rounded)
        }
    }

    private func authorFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:  return .system(size: 13, weight: .medium, design: .rounded)
        case .systemMedium: return .system(size: 14, weight: .medium, design: .rounded)
        case .systemLarge:  return .system(size: 16, weight: .medium, design: .rounded)
        default:            return .system(size: 14, weight: .medium, design: .rounded)
        }
    }

    private func lineLimit(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:  return 4
        case .systemMedium: return 5
        case .systemLarge:  return 7
        default:            return 5
        }
    }
}

// MARK: - Widget
struct QuotieWidget: Widget {
    let kind: String = "QuotieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotieWidgetProvider()) { entry in
            QuotieWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quotie")
        .description("A daily quote from your collection.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct QuotieWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuotieWidget()
    }
}

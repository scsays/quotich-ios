import WidgetKit
import SwiftUI

// 1. Entry
struct QuotieWidgetEntry: TimelineEntry {
    let date: Date
    let message: String
}

// 2. Provider
struct QuotieWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuotieWidgetEntry {
        QuotieWidgetEntry(date: Date(), message: "Placeholder")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuotieWidgetEntry) -> Void) {
        let entry = QuotieWidgetEntry(date: Date(), message: "Snapshot")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuotieWidgetEntry>) -> Void) {
        let entry = QuotieWidgetEntry(
            date: Date(),
            message: "Timeline @ \(Date().formatted(date: .abbreviated, time: .standard))"
        )
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// 3. View
struct QuotieWidgetEntryView: View {
    var entry: QuotieWidgetEntry

    var body: some View {
        ZStack {
            // Make sure this is super obvious so we know it's drawing
            Color.orange.ignoresSafeArea()

            VStack(spacing: 6) {
                Text("Quotie TEST")
                    .font(.headline)
                    .bold()

                Text(entry.message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// 4. Widget
struct QuotieWidget: Widget {
    // ⚠️ Must match the "Kind" in Info.plist
    let kind: String = "QuotieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotieWidgetProvider()) { entry in
            QuotieWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quotie Widget")
        .description("Test widget for Quotie.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// 5. Bundle entry point
@main
struct QuotieWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuotieWidget()
        // Add other widgets / live activities here later
    }
}

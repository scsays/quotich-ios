import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme      // 👈 NEW
    @ObservedObject var store: QuoteStore 
    private let appGroupID = "group.com.QuotichApp.Quotich"

    @AppStorage(
        "widgetDailyQuotesEnabled",
        store: UserDefaults(suiteName: "group.Quotie-Team.Quotie")
    ) private var widgetDailyQuotesEnabled: Bool = true

    var body: some View {
        let material: Material = colorScheme == .dark ? .ultraThinMaterial : .thinMaterial  // 👈 NEW

        NavigationView {
            Form {
                Section(header: Text("About Quotie")) {
                    Text("Quotie is your little quote vault — a place to capture the lines you fall in love with and resurface them later when you need them most.")
                        .font(.body)
                }

                Section(header: Text("How it works")) {
                    Label("Capture quotes you love as colorful cards.", systemImage: "square.fill.text.grid.1x2")
                    Label("Star your favorites to see them more often.", systemImage: "star.fill")
                    Label("Tap “Resurface Now” to bring a quote back to the top of your mind.", systemImage: "sparkles")
                }

                Section(header: Text("Credits")) {
                    Text("Created by Andre Bradford (S.C. Says)")
                    if let version = appVersion {
                        Text("Version \(version)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("Widgets")) {
                    Toggle(isOn: $widgetDailyQuotesEnabled) {
                        Text("Show a daily quote in widgets")
                    }
                    .font(.system(.body, design: .rounded))
                    .toggleStyle(.switch)
                    .padding(.vertical, 4)

                    Text("When enabled, the Quotie widget will show a random quote from your collection each day.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
#if DEBUG
Section("Debug") {
    HStack {
        Text("Storage version")
        Spacer()
        Text("\(currentQuotesStorageVersion)")
            .font(.system(.footnote, design: .monospaced))
            .foregroundColor(.secondary)
    }

    HStack {
        Text("Saved quotes")
        Spacer()
        Text("\(store.quotes.count)")
            .font(.system(.footnote, design: .monospaced))
            .foregroundColor(.secondary)
    }
}
#endif
            }
            .scrollContentBackground(.hidden)                      // 👈 hide Form bg
            .background(
                Rectangle()
                    .fill(material)                                // 👈 glass layer
                    .ignoresSafeArea()
            )
            .navigationTitle("Settings & About")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var appVersion: String? {
        if let info = Bundle.main.infoDictionary {
            let version = info["CFBundleShortVersionString"] as? String ?? ""
            let build = info["CFBundleVersion"] as? String ?? ""
            let versionText = version.isEmpty ? nil : version
            let buildText = build.isEmpty ? nil : "build \(build)"
            return [versionText, buildText]
                .compactMap { $0 }
                .joined(separator: " ")
        }
        return nil
    }
}

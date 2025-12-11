import SwiftUI

struct MonsterStatsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: QuoteStore

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {

                MonsterRingAvatar(
                    progress: Double(store.hungerLevel) / 5.0,
                    collapseT: 0,
                    onTap: {}
                )
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 10) {
                    statRow("Hunger level", "\(store.hungerLevel)/5")
                    statRow("Quotes eaten (this week)", "—")   // we’ll implement next
                    statRow("Quotes eaten (all time)", "—")   // we’ll implement next
                }
                .padding(16)
                .liquidGlass(cornerRadius: 18, scheme: .light) // ok for now

                VStack(alignment: .leading, spacing: 10) {
                    Text("Favorite quote for today")
                        .font(.headline)

                    if let q = store.quoteFor() {
                        Text("“\(q.text)”")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No quotes yet. Feed me your first one.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .liquidGlass(cornerRadius: 18, scheme: .light)

                Spacer()
            }
            .padding(16)
            .navigationTitle("Quote Monster")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                }
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

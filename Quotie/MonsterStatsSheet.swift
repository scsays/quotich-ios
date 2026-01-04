import SwiftUI

struct MonsterStatsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: QuoteStore
    @Environment(\.colorScheme) private var scheme

    @StateObject private var moodService = MemmiMoodService()

    // Memmi reaction state (mirrors QuoteDetailView behavior)
    @State private var memmiMessage: String?
    @State private var isLoadingMemmi = false
    @State private var showMemmiEntrance = false

    private var todayQuote: Quote? {
        store.quoteFor()
    }

    private var currentTodayQuote: Quote? {
        guard let q = todayQuote else { return nil }
        return store.quotes.first(where: { $0.id == q.id }) ?? q
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {

                    MonsterRingAvatar(
                        progress: Double(store.hungerLevel) / 5.0,
                        collapseT: 0,
                        onTap: {}
                    )
                    .padding(.top, 8)

                    // Mood (centered)
                    VStack(spacing: 6) {
                        Text("Memmi Mood")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if moodService.isLoading {
                            ProgressView()
                                .scaleEffect(0.9)
                                .padding(.top, 2)
                        } else {
                            Text(moodService.mood)
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 8)

                    // This Week (based on quotes added, not avatar taps)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week")
                            .font(.headline)

                        HStack(spacing: 14) {
                            statPill(
                                title: "Quotes Devoured",
                                value: String(store.devoursThisWeekCount())
                            )

                            statPill(
                                title: "Top Source",
                                value: store.topSourceLast7Days() ?? "—"
                            )
                        }
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 18, scheme: .light)

                    // All Time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Time")
                            .font(.headline)

                        statPill(
                            title: "Quotes Devoured",
                            value: String(store.devoursAllTimeCount())
                        )
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 18, scheme: .light)

                    // Favorite quote today + reaction (Option B: distinct bubbles)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Memmi’s Favorite Quote Today")
                            .font(.headline)

                        if let q = store.quoteFor() {

                            // QUOTE bubble (distinct style)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quote")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("“\(q.text)”")
                                    .font(.system(.body, design: .serif).italic())
                                    .foregroundStyle(DesignSystem.primaryText(scheme))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(scheme == .dark ? 0.10 : 0.18), lineWidth: 0.8)
                            )

                            // REACTION bubble (Memmi voice)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Memmi")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                let reaction = (q.memmiReaction ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                                if reaction.isEmpty {
                                    Text("Memmi is chewing on this…")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(reaction)
                                        .font(.subheadline)
                                        .foregroundStyle(DesignSystem.primaryText(scheme))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.18 : 0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.35 : 0.25), lineWidth: 0.9)
                            )

                        } else {
                            Text("No quotes yet. Feed me your first one.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 18, scheme: scheme)
                    Spacer(minLength: 10)
                }
                .padding(16)
            }
            .navigationTitle("Memmi Monster")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                }
            }
            .onAppear {
                moodService.loadCachedMoodIfValid()

                Task {
                    let weekly = store.weeklyDevouredQuoteTexts()
                    await moodService.refreshMood(using: weekly)
                }

                Task { await loadMemmiForTodayQuote() }
            }
        }
    }

    // MARK: - Memmi Reaction UI (mirrors QuoteDetailView feel)

    @ViewBuilder
    private func memmiReactionView(for quote: Quote) -> some View {
        if isLoadingMemmi {
            MemmiBubble(text: "Memmi is chewing on this…")
                .opacity(0.7)
                .frame(maxWidth: .infinity, alignment: .center)

        } else if let memmiMessage {
            MemmiBubble(text: memmiMessage)
                .scaleEffect(showMemmiEntrance ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showMemmiEntrance)
                .frame(maxWidth: .infinity, alignment: .center)

        } else {
            // If nothing yet, show the “chewing” placeholder (like QuoteDetailView does)
            MemmiBubble(text: "Memmi is chewing on this…")
                .opacity(0.6)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Memmi Reaction Loader (same caching pattern as QuoteDetailView)

    private func loadMemmiForTodayQuote() async {
        guard let q = currentTodayQuote else { return }

        // 1) If already cached on the quote, use it and bail
        if let cached = q.memmiReaction, !cached.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            memmiMessage = cached
            return
        }

        await MainActor.run { isLoadingMemmi = true }

        do {
            let response = try await MemmiService.shared.enrichQuote(q.text)

            await MainActor.run {
                memmiMessage = response.memmi
                isLoadingMemmi = false
                showMemmiEntrance = true
            }

            // 2) Save reaction back into QuoteStore (same as QuoteDetailView)
            store.updateMemmiReaction(for: q.id, reaction: response.memmi)

            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run { showMemmiEntrance = false }
            }

        } catch {
            await MainActor.run {
                memmiMessage = "Memmi lost the thought. Try again?"
                isLoadingMemmi = false
            }
        }
    }

    // MARK: - Stat Pill

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.35))
        )
    }
}

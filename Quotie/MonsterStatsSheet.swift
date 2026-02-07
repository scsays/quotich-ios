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

    private var todayQuote: Quote? { store.quoteFor() }

    private var currentTodayQuote: Quote? {
        guard let q = todayQuote else { return nil }
        return store.quotes.first(where: { $0.id == q.id }) ?? q
    }

    var body: some View {
        NavigationView {
            let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {

                        // ✅ Back row (matches Snack Bar vibe)
                        topBackRow
                            .padding(.top, 10)

                        // ✅ Big centered page title (separate row, never overlaps Back)
                        Text("Memmi Monster")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(DesignSystem.primaryText(scheme))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.top, 6)

                        MonsterRingAvatar(
                            progress: Double(store.hungerLevel) / 5.0,
                            collapseT: 0,
                            onTap: {}
                        )
                        .padding(.top, 6)

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

                        // This Week
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

                        // Favorite quote today + reaction
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Memmi’s Favorite Quote Today")
                                .font(.headline)

                            if let q = store.quoteFor() {

                                // QUOTE bubble
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

                                    let reaction = (q.memmiReaction ?? "")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)

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
                                        .stroke(
                                            DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.35 : 0.25),
                                            lineWidth: 0.9
                                        )
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
            }
            // ✅ Hide system nav bar so we don’t get duplicate title/back
            .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Top Back Row (Snack Bar style)

    private var topBackRow: some View {
        HStack {
            Button { dismiss() } label: {
                Text("Back")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white) // ✅ avoid blue "tint" look
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(DesignSystem.glassMaterial(for: scheme))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(scheme == .dark ? 0.14 : 0.20), lineWidth: 0.9)
                            )
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Memmi Reaction Loader

    private func loadMemmiForTodayQuote() async {
        guard let q = currentTodayQuote else { return }

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

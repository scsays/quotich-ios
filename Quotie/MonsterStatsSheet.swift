import SwiftUI

struct MonsterStatsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: QuoteStore
    @Environment(\.colorScheme) private var scheme

    @AppStorage("memmi.displayName") private var memmiName: String = "Memmi"
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

    private var displayName: String {
        let trimmed = memmiName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Memmi" : trimmed
    }

    private var favoritePercentageText: String {
        guard store.devoursAllTimeCount() > 0 else { return "0%" }
        let percent = Double(store.favoriteQuotesCount()) / Double(store.devoursAllTimeCount()) * 100
        return "\(Int(percent.rounded()))%"
    }

    var body: some View {
        NavigationView {
            let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        topBackRow
                            .padding(.top, 10)

                        heroCard

                        statsSection

                        favoriteQuoteSection

                        Spacer(minLength: 10)
                    }
                    .padding(16)
                }
            }
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

    // MARK: - Sections

    private var heroCard: some View {
        VStack(spacing: 16) {
            heroAvatar
            nameEditor
            moodCard
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(heroBackground)
        .overlay(heroStroke)
        .shadow(color: heroShadowColor, radius: 18, x: 0, y: 10)
    }

    private var heroAvatar: some View {
        MonsterRingAvatar(
            progress: MonsterMood.visualProgress(fromHungerLevel: store.hungerLevel),
            collapseT: 0,
            badgeFontStyle: store.majorityFontStyle(),
            onTap: {}
        )
        .padding(.top, 4)
    }

    private var nameEditor: some View {
        VStack(spacing: 8) {
            Text("\(displayName) Monster")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(DesignSystem.primaryText(scheme))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Rename Memmi", text: $memmiName)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(false)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(nameEditorBackground)
            .overlay(nameEditorStroke)
            .padding(.horizontal, 24)
        }
    }

    private var heroBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(heroGradient)
    }

    private var heroStroke: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(scheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.70), lineWidth: 1)
    }

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.26 : 0.30),
                scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.62)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroShadowColor: Color {
        Color.black.opacity(scheme == .dark ? 0.34 : 0.12)
    }

    private var nameEditorBackground: some View {
        Capsule(style: .continuous)
            .fill(scheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.58))
    }

    private var nameEditorStroke: some View {
        Capsule(style: .continuous)
            .stroke(scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.06), lineWidth: 1)
    }

    private var moodCard: some View {
        VStack(spacing: 8) {
            Text("Current Mood")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)

            if moodService.isLoading {
                ProgressView()
                    .scaleEffect(0.9)
                    .padding(.top, 2)
            } else {
                Text(moodService.mood)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(DesignSystem.primaryText(scheme))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Text(moodCaption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(scheme == .dark ? Color.black.opacity(0.22) : Color.white.opacity(0.48))
        )
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Memmi’s Appetite")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statTile(title: "This Week", value: String(store.devoursThisWeekCount()), caption: "quotes devoured", systemImage: "calendar")
                statTile(title: "Best Week", value: String(store.mostDevoursInAWeekCount()), caption: "personal record", systemImage: "flame.fill")
                statTile(title: "Favorites", value: String(store.favoriteQuotesCount()), caption: "\(favoritePercentageText) of vault", systemImage: "heart.fill")
                statTile(title: "All Time", value: String(store.devoursAllTimeCount()), caption: "total devoured", systemImage: "archivebox.fill")
            }

            sourceInsightCard
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, scheme: scheme)
    }

    private var sourceInsightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "text.quote")
                    .foregroundStyle(DesignSystem.monsterPurple)

                Text("Source Taste")
                    .font(.headline)

                Spacer()
            }

            HStack(alignment: .top, spacing: 12) {
                sourceColumn(title: "This week", value: store.topSourceLast7Days() ?? "No source yet")
                Divider().opacity(0.35)
                sourceColumn(title: "All time", value: store.topSourceAllTime() ?? "No source yet")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.45))
        )
    }

    private var favoriteQuoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Today’s Snack")

            if let q = store.quoteFor() {
                QuoteCardView(
                    quote: q,
                    onToggleFavorite: {},
                    isHighlighted: false
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 8) {
                    Text(displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    let reaction = (q.memmiReaction ?? memmiMessage ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if isLoadingMemmi || reaction.isEmpty {
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.45))
                    )
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, scheme: scheme)
    }

    // MARK: - Top Back Row

    private var topBackRow: some View {
        HStack {
            Button { dismiss() } label: {
                Text("Back")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(DesignSystem.monsterPurple)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        Color.white.opacity(0.18),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(scheme == .dark ? 0.22 : 0.10),
                        radius: 12,
                        x: 0,
                        y: 5
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Color.clear
                .frame(width: 72, height: 1)
        }
    }

    // MARK: - Small Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(DesignSystem.primaryText(scheme))
    }

    private func statTile(title: String, value: String, caption: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.monsterPurple)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(DesignSystem.primaryText(scheme))

            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.28), lineWidth: 0.8)
        )
    }

    private func sourceColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(DesignSystem.primaryText(scheme))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var moodCaption: String {
        if store.devoursThisWeekCount() == 0 {
            return "Feed Memmi a quote this week to shape their mood."
        }

        return "Based on the tone of quotes fed in the last 7 days."
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
}

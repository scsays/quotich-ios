import SwiftUI

struct HomeFeedView: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var store: QuoteStore

    let favoritesOnly: Bool
    @Binding var isScrolling: Bool

    @State private var scrollY: CGFloat = 0
    @State private var showingMonsterStats = false
    @State private var selectedQuote: Quote? = nil

    // 0 = hero, 1 = collapsed header
    private var collapseT: CGFloat {
        let start: CGFloat = 10     // when transition starts
        let end: CGFloat = 140      // when fully collapsed
        let t = (scrollY - start) / (end - start)
        return min(max(t, 0), 1)
    }

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        ZStack(alignment: .top) {
            bg.ignoresSafeArea()

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 14
                ) {
                    ForEach(filteredQuotes) { quote in
                        MasonryQuoteCard(quote: quote) {
                            store.toggleFavorite(quote)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedQuote = quote }
                    }
                }
                .padding(.horizontal, 16)

                // ✅ Keep your “hero” spacing when at top.
                // As you collapse, we reduce the top padding so content moves up.
                .padding(.top, lerp(160, 92, collapseT))
                .padding(.bottom, 110)
            }
            .trackScrollPhase(isScrolling: $isScrolling)
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, newOffset in
                scrollY = newOffset
            }

            // ✅ Overlay the top UI
            topMonsterAndHeader(bg: bg)
        }
        .sheet(isPresented: $showingMonsterStats) {
            MonsterStatsSheet()
                .environmentObject(store)
        }
        .sheet(item: $selectedQuote) { quote in
            QuoteDetailView(quote: quote)
                .environmentObject(store)
        }
    }

    private var filteredQuotes: [Quote] {
        favoritesOnly ? store.quotes.filter { $0.isFavorite } : store.quotes
    }

    // MARK: - Top Overlay (Hero ring -> Header line)
    private func topMonsterAndHeader(bg: Color) -> some View {
        let t = collapseT
        let heroOpacity = Double(1 - t)
        let headerOpacity = Double(t)

        // ✅ Move the header down (below Dynamic Island) WITHOUT ignoresSafeArea hacks
        let headerTopPad: CGFloat = 10

        // ✅ Thin-ish header (just enough to hold the meter)
        let headerHeight: CGFloat = 44

        // ✅ How "see-through" the header is
        let headerBaseOpacity: Double = scheme == .dark ? 0.92 : 0.88

        return ZStack(alignment: .top) {

            // --- HEADER STATE (fades IN as you scroll) ---
            VStack(spacing: 0) {

                // 1) SOLID BLACK TOP (status bar safety)
                // This guarantees the status bar area is NOT transparent.
                bg
                    .frame(height: 56) // 👈 adjust 48–64 if you want it higher/lower

                // 2) LOWER HEADER ZONE (mostly solid, with a tiny transparent strip near the bottom)
                ZStack(alignment: .bottom) {

                    // Mostly-solid header body
                    bg
                        .opacity(scheme == .dark ? 0.98 : 0.94)

                    // Tiny "peek" strip so quotes *slightly* show right above the meter
                    LinearGradient(
                        colors: [
                            bg.opacity(1.0),                    // solid above
                            bg.opacity(scheme == .dark ? 0.78 : 0.72) // slightly transparent right near bottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 18) // 👈 this controls how tall the “peek” strip is

                    // Hunger meter pinned to the bottom of the header
                    hungerMeterWithMonsterThumb(
                        progress: Double(store.hungerLevel) / 5.0,
                        thumbOpacity: headerOpacity
                    )
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                }
                .frame(height: 56) // 👈 height of the header area that contains the meter
            }
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.18), value: t)
            .ignoresSafeArea(edges: .top)

            // --- HERO STATE (stays the same until you scroll) ---
            VStack(spacing: 0) {
                MonsterRingAvatar(
                    progress: Double(store.hungerLevel) / 5.0,
                    collapseT: collapseT,
                    onTap: { showingMonsterStats = true }
                )
                .padding(.top, 18)
                .scaleEffect(lerp(1.0, 0.70, t))
                .opacity(heroOpacity)
            }
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: t)
        }
    }

    // MARK: - Helpers
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }


    // Thick, glowing hunger meter line + monster thumb at the endpoint
    private func hungerMeterWithMonsterThumb(progress: Double, thumbOpacity: Double) -> some View {
        let clamped = min(max(progress, 0), 1)

        // ✅ One source of truth for sizing
        let thumbSize: CGFloat = 34     // <-- increase this to 36–40 if you want even beefier
        let barH: CGFloat = 12          // <-- thicker meter line

        return GeometryReader { geo in
            let w = geo.size.width

            // Fill width (keep a tiny minimum so you can always see “something”)
            let fillW = max(barH, w * CGFloat(clamped))

            // Thumb x-position = true endpoint of progress
            let thumbCenterX = w * CGFloat(clamped)
            let thumbX = min(max(thumbCenterX - thumbSize / 2, 0), w - thumbSize)

            ZStack(alignment: .leading) {

                // Track (centered vertically)
                Capsule()
                    .fill(Color.white.opacity(scheme == .dark ? 0.10 : 0.16))
                    .frame(height: barH)
                    .overlay(
                        Capsule()
                            .stroke(DesignSystem.monsterPurple.opacity(0.35), lineWidth: 1)
                    )
                    .position(x: w / 2, y: thumbSize / 2)

                // Fill (centered vertically)
                Capsule()
                    .fill(DesignSystem.monsterPurple.opacity(0.92))
                    .frame(width: fillW, height: barH)
                    .shadow(color: DesignSystem.monsterPurple.opacity(0.55), radius: 10, y: 0)
                    .shadow(color: DesignSystem.monsterPurple.opacity(0.25), radius: 18, y: 0)
                    .position(x: fillW / 2, y: thumbSize / 2)

                // Thumb (monster) centered on the bar’s centerline
                Image("QuoteMonster")
                    .resizable()
                    .scaledToFit()
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                    .opacity(thumbOpacity)
                    .offset(x: thumbX, y: 0)
            }
        }
        .frame(height: thumbSize) // ✅ makes the thumb “fill” the meter’s vertical space
    }
}

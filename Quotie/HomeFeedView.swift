import SwiftUI
import UniformTypeIdentifiers

struct HomeFeedView: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var store: QuoteStore

    let viewMode: HomeViewMode
    let isSearchActive: Bool
    @Binding var isScrolling: Bool

    @State private var scrollY: CGFloat = 0
    @State private var showingMonsterStats = false

    // Drag state (UUID-based)
    @State private var draggingID: UUID? = nil

    // ✅ Forces the grid to rebuild after a drop (this fixes the “taps stop working” bug)
    @State private var gridRefreshID = UUID()

    // Sheet item that always re-triggers reliably
    private struct QuoteSheetItem: Identifiable, Equatable { let id: UUID }
    @State private var quoteSheetItem: QuoteSheetItem? = nil

    @State private var selectedCardIndex = 0
    @State private var previousCardIndex = 0
    @AppStorage("memmi.cardViewDidSwipeLeft") private var didSwipeLeftInCardView = false
    @AppStorage("memmi.cardViewDidSwipeRight") private var didSwipeRightInCardView = false

    // 0 = hero, 1 = collapsed header
    private var collapseT: CGFloat {
        let start: CGFloat = 10
        let end: CGFloat = 140
        let t = (scrollY - start) / (end - start)
        return min(max(t, 0), 1)
    }

    // Only allow reordering on the “true” home feed (no filters/search)
    private var canReorder: Bool { false }

    private var filteredQuotes: [Quote] {
        let base = viewMode == .favorites ? store.quotes.filter { $0.isFavorite } : store.quotes
        return base.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        ZStack(alignment: .top) {
            bg.ignoresSafeArea()

            if viewMode == .card {
                cardPager
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ],
                        spacing: 14
                    ) {
                        ForEach(filteredQuotes) { quote in
                            quoteCell(quote)
                        }
                    }
                    .id(gridRefreshID) // ✅ key fix: rebuild the grid when we say so
                    .padding(.horizontal, 16)
                    .padding(.top, lerp(160, 92, collapseT))
                    .padding(.bottom, 110)
                    .background(catchAllDropTarget) // ✅ drop reset without overlaying touches
                }
                .trackScrollPhase(isScrolling: $isScrolling)
                .onScrollGeometryChange(for: CGFloat.self) { geo in geo.contentOffset.y } action: { _, newOffset in
                    scrollY = newOffset
                }
            }

            topMonsterAndHeader(bg: bg)
        }
        .sheet(isPresented: $showingMonsterStats) {
            MonsterStatsSheet()
                .environmentObject(store)
        }
        .sheet(item: $quoteSheetItem, onDismiss: {
            quoteSheetItem = nil
        }) { item in
            if let q = store.quotes.first(where: { $0.id == item.id }) {
                QuoteDetailView(quote: q)
                    .environmentObject(store)
            } else {
                EmptyView()
            }
        }
        .onChange(of: viewMode) { mode in
            if mode == .card {
                isScrolling = false
                scrollY = 0
            }
        }
    }

    // MARK: - Card View
    private var cardPager: some View {
        Group {
            if filteredQuotes.isEmpty {
                emptyCardView
            } else {
                TabView(selection: $selectedCardIndex) {
                    ForEach(Array(filteredQuotes.enumerated()), id: \.element.id) { index, quote in
                        largeQuoteCard(quote, index: index, totalCount: filteredQuotes.count)
                            .padding(.horizontal, 22)
                            .padding(.top, 210)
                            .padding(.bottom, 96)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .onChange(of: selectedCardIndex) { newIndex in
                    if newIndex > previousCardIndex {
                        didSwipeLeftInCardView = true
                    } else if newIndex < previousCardIndex {
                        didSwipeRightInCardView = true
                    }
                    previousCardIndex = newIndex
                }
                .onChange(of: filteredQuotes.count) { count in
                    selectedCardIndex = min(selectedCardIndex, max(count - 1, 0))
                    previousCardIndex = selectedCardIndex
                }
            }
        }
    }

    private var emptyCardView: some View {
        VStack(spacing: 12) {
            Image(systemName: viewMode == .favorites ? "heart" : "quote.opening")
                .font(DesignSystem.appFont(size: 34, weight: .bold))
                .foregroundStyle(DesignSystem.monsterPurple)
            Text(viewMode == .favorites ? "No favorites yet" : "No quotes yet")
                .font(DesignSystem.appFont(.title3, weight: .bold))
            Text(viewMode == .favorites ? "Favorite a quote, then it’ll show up here." : "Tap + to feed Memmi a quote.")
                .font(DesignSystem.appFont(.subheadline))
                .foregroundStyle(DesignSystem.secondaryText(scheme))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }

    private func largeQuoteCard(_ quote: Quote, index: Int, totalCount: Int) -> some View {
        Button {
            quoteSheetItem = QuoteSheetItem(id: quote.id)
        } label: {
            VStack(alignment: .leading, spacing: 18) {
                Spacer(minLength: 0)

                Text("“\(quote.text)”")
                    .font(DesignSystem.quoteFont(quote.fontStyle, textStyle: .title, weight: .semibold))
                    .foregroundStyle(DesignSystem.primaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                if !quote.author.isEmpty || !quote.source.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if !quote.author.isEmpty {
                            Text("— \(quote.author)")
                                .font(DesignSystem.appFont(.headline, weight: .bold))
                        }
                        if !quote.source.isEmpty {
                            Text(quote.source)
                                .font(DesignSystem.appFont(.subheadline, weight: .semibold))
                        }
                    }
                    .foregroundStyle(DesignSystem.secondaryText(scheme))
                }

                Spacer(minLength: 0)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        if index < totalCount - 1 && !didSwipeLeftInCardView {
                            Label("Swipe left for older quotes", systemImage: "arrow.left")
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        }

                        if index > 0 && !didSwipeRightInCardView {
                            Label("Swipe right for newer quotes", systemImage: "arrow.right")
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .font(DesignSystem.appFont(.caption, weight: .semibold))
                    .foregroundStyle(DesignSystem.secondaryText(scheme))
                    .animation(.easeOut(duration: 0.2), value: didSwipeLeftInCardView)
                    .animation(.easeOut(duration: 0.2), value: didSwipeRightInCardView)

                    Spacer()

                    Image(systemName: quote.isFavorite ? "heart.fill" : "heart")
                        .font(DesignSystem.appFont(size: 18, weight: .heavy))
                        .foregroundStyle(quote.isFavorite ? DesignSystem.monsterPurple : DesignSystem.secondaryText(scheme))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(DesignSystem.cardGradient(for: quote.colorStyle, scheme: scheme))
                    .shadow(color: DesignSystem.cardShadow, radius: 18, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quote Cell (Tap + Drag/Drop)
    @ViewBuilder
    private func quoteCell(_ quote: Quote) -> some View {
        // ✅ Use a Button for the main tap (more reliable than onTapGesture here)
        Button {
            // If a drag is still “logically active”, clear it instead of blocking taps forever
            if draggingID != nil {
                draggingID = nil
                gridRefreshID = UUID()
            }

            // Present sheet (force retrigger)
            quoteSheetItem = nil
            DispatchQueue.main.async {
                quoteSheetItem = QuoteSheetItem(id: quote.id)
            }
        } label: {
            MasonryQuoteCard(quote: quote) {
                store.toggleFavorite(quote)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .if(canReorder) { view in
            view
                .onDrag {
                    draggingID = quote.id
                    return NSItemProvider(object: quote.id.uuidString as NSString)
                }
                .onDrop(
                    of: [UTType.plainText, UTType.text],
                    delegate: QuoteReorderDropDelegate(
                        targetID: quote.id,
                        items: $store.quotes,
                        draggingID: $draggingID,
                        onDropEnded: {
                            // ✅ the other key fix: always rebuild after drop
                            draggingID = nil
                            gridRefreshID = UUID()
                        }
                    )
                )
        }
    }

    // MARK: - Drop “catch-all” (only for clearing stuck drag sessions)
    private var catchAllDropTarget: some View {
        Color.clear
            .contentShape(Rectangle())
            .onDrop(of: [UTType.plainText, UTType.text], isTargeted: nil) { _ in
                draggingID = nil
                gridRefreshID = UUID() // ✅ rebuild restores tap reliability
                return true
            }
    }

    // MARK: - Top Overlay (unchanged)
    private func topMonsterAndHeader(bg: Color) -> some View {
        let t = collapseT
        let heroOpacity = Double(1 - t)
        let headerOpacity = Double(t)

        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                bg.frame(height: 56)

                ZStack(alignment: .bottom) {
                    bg.opacity(scheme == .dark ? 0.98 : 0.94)

                    LinearGradient(
                        colors: [bg.opacity(1.0), bg.opacity(scheme == .dark ? 0.78 : 0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 18)

                    hungerMeterWithMonsterThumb(
                        progress: MonsterMood.visualProgress(fromHungerLevel: store.hungerLevel),
                        thumbOpacity: headerOpacity
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                }
                .frame(height: 56)
            }
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.18), value: t)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                MonsterRingAvatar(
                    progress: MonsterMood.visualProgress(fromHungerLevel: store.hungerLevel),
                    collapseT: collapseT,
                    badgeFontStyle: store.majorityFontStyle(),
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
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    private func hungerMeterWithMonsterThumb(progress: Double, thumbOpacity: Double) -> some View {
        let clamped = min(max(progress, 0), 1)

        let baseThumb: CGFloat = 42
        let barH: CGFloat = 12
        let baseScale: CGFloat = lerp(1.0, 1.25, CGFloat(clamped))
        let fullBump: CGFloat = clamped > 0.985 ? 1.10 : 1.0
        let thumbSize: CGFloat = baseThumb * baseScale * fullBump
        let endOverlap: CGFloat = clamped > 0.985 ? thumbSize * 0.28 : 0

        return GeometryReader { geo in
            let w = geo.size.width
            let rawFillW: CGFloat = w * CGFloat(clamped) + endOverlap
            let fillW: CGFloat = min(w, max(barH, rawFillW))

            let rawThumbX: CGFloat = (w * CGFloat(clamped)) - (thumbSize / 2)
            let clampedThumbX: CGFloat = min(max(rawThumbX, 0), w - thumbSize)

            let thumbX: CGFloat = clamped > 0.985
                ? (w - thumbSize) + (endOverlap * 0.85)
                : clampedThumbX

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(scheme == .dark ? 0.10 : 0.16))
                    .frame(height: barH)
                    .overlay(Capsule().stroke(DesignSystem.monsterPurple.opacity(0.35), lineWidth: 1))
                    .position(x: w / 2, y: thumbSize / 2)

                Capsule()
                    .fill(DesignSystem.monsterPurple.opacity(0.92))
                    .frame(width: fillW, height: barH)
                    .shadow(color: DesignSystem.monsterPurple.opacity(0.55), radius: 10, y: 0)
                    .shadow(color: DesignSystem.monsterPurple.opacity(0.25), radius: 18, y: 0)
                    .position(x: fillW / 2, y: thumbSize / 2)

                let mood = MonsterMood.from(progress: clamped)
                if let uiImage = MemmiImageCache.image(named: mood.assetName, scheme: scheme) ?? UIImage(named: "QuoteMonster") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.20), radius: 6, y: 3)
                        .opacity(thumbOpacity)
                        .offset(x: thumbX, y: 0)
                }
            }
        }
        .frame(height: thumbSize)
    }
}

// tiny helper for conditional modifiers
private extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

import SwiftUI
import WidgetKit

// MARK: - Global Colors

let lightPaperBackground = Color(red: 0.97, green: 0.96, blue: 0.95)
let darkPaperBackground  = Color(red: 0.06, green: 0.06, blue: 0.08)

// MARK: - Main View

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var store = QuoteStore()
    @State private var highlightedQuoteID: UUID?

    // UI State
    @State private var showingAddSheet = false
    @State private var showFavoritesOnly = false
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var selectedQuoteForDetail: Quote?

    // Quote Monster State
    @State private var monsterMood: MonsterMood = .neutral
    @State private var showingMonsterCard = false
    @State private var isDocked = false   // single source of truth

    var body: some View {
        let bg = colorScheme == .dark ? darkPaperBackground : lightPaperBackground

        NavigationView {
            ZStack(alignment: .top) {

                // Background
                bg
                    .ignoresSafeArea()
                    .background(
                        LinearGradient(
                            colors: [
                                bg,
                                bg.opacity(colorScheme == .dark ? 0.92 : 0.96)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .onAppear {
                        store.applyDailyHungerDecay()
                    }

                // Scroll Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        cardsList
                    }
                    .padding(.top, 200)
                    .padding(.bottom, 16)
                }
                .onChange(of: searchText) {
                    isDocked = false
                }
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { _ in
                            if !isDocked {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                    isDocked = true
                                }
                            }
                        }
                )

                // Header
                HeaderChromeView {
                    showingSettings = true
                }

                // Floating Monster
                floatingMonster
            }
            .safeAreaInset(edge: .bottom) {
                BottomControlBar(
                    searchText: $searchText,
                    showFavoritesOnly: $showFavoritesOnly,
                    onSearchTapped: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            isDocked = false
                        }
                    },
                    onAddQuote: { showingAddSheet = true }
                )
            }
            .background(bg)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) {
                AddQuoteView(store: store)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(store: store)
            }
            .sheet(item: $selectedQuoteForDetail) { quote in
                QuoteDetailView(quote: quote)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingMonsterCard) {
                QuoteMonsterCardView(
                    store: store,
                    onFeedMe: { showingAddSheet = true }
                )
            }
        }
    }
    // MARK: - Floating Monster

    private var floatingMonster: some View {
        GeometryReader { geo in
            VStack(spacing: 10) {
                QuoteMonsterView(mood: monsterMood)
                    .scaleEffect(isDocked ? 0.9 : 1.15)
                    .opacity(0.95)

                if !isDocked {
                    hungerMeter
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(
                x: isDocked ? geo.size.width / 2 - 70 : 0,
                y: isDocked ? 72 : 110
            )
            .animation(
                .spring(response: 0.45, dampingFraction: 0.9),
                value: isDocked
            )
            .onTapGesture {
                showingMonsterCard = true
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Hunger Meter

    private var hungerProgress: CGFloat {
        CGFloat(store.hungerLevel) / 5.0
    }

    private var hungerMeter: some View {
        VStack(spacing: 6) {
            Text("Hunger Meter")
                .font(.caption2)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))

                    Capsule()
                        .fill(Color.white)
                        .frame(width: geo.size.width * hungerProgress)
                        .shadow(
                            color: Color.white.opacity(0.6),
                            radius: 6
                        )
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }

    // MARK: - Cards List

    private var cardsList: some View {
        ForEach(filteredQuotes) { quote in
            QuoteCardView(
                quote: quote,
                onToggleFavorite: {
                    withAnimation {
                        store.toggleFavorite(quote)
                    }
                },
                isHighlighted: highlightedQuoteID == quote.id
            )
            .padding(.horizontal)
            .onTapGesture {
                selectedQuoteForDetail = quote
            }
        }
    }

    // MARK: - Filtering

    private var filteredQuotes: [Quote] {
        let base = showFavoritesOnly
            ? store.quotes.filter { $0.isFavorite }
            : store.quotes

        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return base
        }

        let lower = searchText.lowercased()
        return base.filter {
            $0.text.lowercased().contains(lower) ||
            $0.author.lowercased().contains(lower) ||
            $0.source.lowercased().contains(lower)
        }
    }
}

struct HeaderChromeView: View {
    var onSettings: () -> Void

    var body: some View {
        HStack {
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

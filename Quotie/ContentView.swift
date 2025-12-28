import SwiftUI
import Combine
import WidgetKit

// MARK: - Global Colors

let lightPaperBackground = Color(red: 0.97, green: 0.96, blue: 0.95)
let darkPaperBackground  = Color(red: 0.06, green: 0.06, blue: 0.08)

// MARK: - Main View

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var store = QuoteStore()

    // UI state
    @State private var showingAddSheet = false
    @State private var showingSettings = false
    @State private var selectedQuoteForDetail: Quote?
    @State private var showFavoritesOnly = false
    @State private var searchText = ""
    @State private var showingSnackBar = false

    // Monster
    @State private var isDocked = false
    @State private var showingMonsterCard = false

    var body: some View {
        
        let bg = colorScheme == .dark ? darkPaperBackground : lightPaperBackground

        NavigationView {
            ZStack(alignment: .top) {

                // Background
                bg
                    .ignoresSafeArea()
                    .onAppear {
                        store.applyDailyHungerDecay()
                    }

                // Main feed
                ScrollView {
                    LazyVStack(spacing: 16) {
                        cardsList
                    }
                    .padding(.top, 200)
                    .padding(.bottom, 16)
                }

                // Header (gear only)
                HeaderChromeView {
                    showingSettings = true
                }

                // Floating monster
                floatingMonster
            }

            // ✅ Bottom bar ONLY when Snack Bar is NOT showing
            .safeAreaInset(edge: .bottom) {
                if !showingSnackBar {
                    BottomControlBar(
                        searchText: $searchText,
                        showFavoritesOnly: $showFavoritesOnly,
                        onSearchTapped: {
                            withAnimation(.spring()) {
                                isDocked = false
                            }
                        },
                        onAddQuote: {
                            showingAddSheet = true
                        },
                        onSnackBar: {
                            showingSnackBar = true
                        }
                    )
                }
            }

            .toolbar(.hidden, for: .navigationBar)

            // MARK: - Sheets & Full Screens

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

            // ✅ Snack Bar is FULL SCREEN
            .fullScreenCover(isPresented: $showingSnackBar) {
                SnackBarView(onBack: {
                    showingSnackBar = false
                })
                .environmentObject(store)
            }
        }
    }

    // MARK: - Floating Monster

    private var floatingMonster: some View {
        GeometryReader { geo in
            VStack(spacing: 10) {
                QuoteMonsterView(mood: .neutral)
                    .scaleEffect(isDocked ? 0.9 : 1.15)

                if !isDocked {
                    hungerMeter
                }
            }
            .frame(maxWidth: .infinity)
            .offset(
                x: isDocked ? geo.size.width / 2 - 70 : 0,
                y: isDocked ? 72 : 110
            )
            .animation(.spring(), value: isDocked)
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
                        .shadow(radius: 6)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }

    // MARK: - Cards

    private var cardsList: some View {
        ForEach(filteredQuotes) { quote in
            QuoteCardView(
                quote: quote,
                onToggleFavorite: {
                    withAnimation {
                        store.toggleFavorite(quote)
                    }
                },
                isHighlighted: false
            )
            .padding(.horizontal)
            .onTapGesture {
                selectedQuoteForDetail = quote
            }
        }
    }

    private var filteredQuotes: [Quote] {
        let base = showFavoritesOnly
            ? store.quotes.filter { $0.isFavorite }
            : store.quotes

        guard !searchText.isEmpty else { return base }

        return base.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Header (gear only)

struct HeaderChromeView: View {
    var onSettings: () -> Void

    var body: some View {
        HStack {
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}


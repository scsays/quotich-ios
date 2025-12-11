import SwiftUI
import WidgetKit

// MARK: - Global Colors

let lightPaperBackground = Color(red: 0.97, green: 0.96, blue: 0.95)
let darkPaperBackground  = Color(red: 0.06, green: 0.06, blue: 0.08)

// MARK: - Sample Quotes (used if no saved data yet)

let sampleQuotes: [Quote] = [
    Quote(
        text: "You don’t have to feel ready to start, you just have to start.",
        author: "S.C. Says",
        source: "Keynote",
        isFavorite: true,
        colorStyle: .peach,
        fontStyle: .rounded
    ),
    Quote(
        text: "Be kind, for everyone you meet is fighting a hard battle.",
        author: "Ian Maclaren (attributed)",
        source: "Conversation",
        colorStyle: .lilac,
        fontStyle: .serif
    ),
    Quote(
        text: "Attention is the rarest and purest form of generosity.",
        author: "Simone Weil",
        source: "Book",
        colorStyle: .sky,
        fontStyle: .standard
    )
]

// MARK: - Main View

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var store = QuoteStore()

    @State private var showingAddSheet = false
    @State private var showFavoritesOnly = false
    @State private var resurfacedQuote: Quote?
    @State private var showingResurfaceSheet = false
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var selectedQuoteForDetail: Quote?

    var body: some View {
        let bg = colorScheme == .dark ? darkPaperBackground : lightPaperBackground

        NavigationView {
            ZStack(alignment: .top) {
                bg.ignoresSafeArea()

                // Main scroll content
                ScrollView {
                    LazyVStack(spacing: 16) {

                        // Title that scrolls away with content
                        HStack {
                            Text("Quotie")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 20)
                                .padding(.bottom, 4)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                        ForEach(filteredQuotes) { quote in
                            QuoteCardView(quote: quote) {
                                withAnimation {
                                    store.toggleFavorite(quote)
                                }
                            }
                            .padding(.horizontal)
                            .onTapGesture {
                                selectedQuoteForDetail = quote
                            }
                            .contextMenu {
                                Button {
                                    withAnimation {
                                        store.toggleFavorite(quote)
                                    }
                                } label: {
                                    Label(
                                        quote.isFavorite ? "Remove from favorites" : "Add to favorites",
                                        systemImage: quote.isFavorite ? "star.slash" : "star"
                                    )
                                }

                                Button(role: .destructive) {
                                    withAnimation {
                                        store.delete(quote)
                                    }
                                } label: {
                                    Label("Delete quote", systemImage: "trash")
                                }
                            }
                            .onAppear {
                                // Test App Group access
                                if let defaults = UserDefaults(suiteName: "group.com.QuotichApp.Quotich") {
                                    defaults.set("test", forKey: "testKey")
                                    print("✅ App Group is accessible")
                                } else {
                                    print("❌ App Group is NOT accessible")
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }

                // Top glass buttons pinned over content
                HeaderChromeView(
                    onSettings: { showingSettings = true },
                    onResurface: handleResurface
                )
            }
            // Bottom control bar
            .safeAreaInset(edge: .bottom) {
                BottomControlBar(
                    searchText: $searchText,
                    showFavoritesOnly: $showFavoritesOnly,
                    onAddQuote: {
                        showingAddSheet = true
                    }
                )
            }
            .background(bg)
            .dynamicTypeSize(.small ... .accessibility3)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) {
                AddQuoteView(store: store)
                    .presentationDetents([.large])
                          .presentationDragIndicator(.visible)
                          .presentationBackground(.ultraThinMaterial)
            }
            .sheet(isPresented: $showingResurfaceSheet) {
                if let resurfacedQuote {
                    ResurfaceView(quote: resurfacedQuote)
                        .presentationDetents([.medium, .large])
                              .presentationDragIndicator(.visible)
                              .presentationBackground(.ultraThinMaterial)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(store: store)
                    .presentationDetents([.medium, .large])
                          .presentationDragIndicator(.visible)
                          .presentationBackground(.ultraThinMaterial)
            }
            .sheet(item: $selectedQuoteForDetail) { quote in
                QuoteDetailView(store: store, quote: quote)
            }
        }
    }

    // MARK: - Computed

    private var filteredQuotes: [Quote] {
        // Favorites filter first
        let base: [Quote]
        if showFavoritesOnly {
            base = store.quotes.filter { $0.isFavorite }
        } else {
            base = store.quotes
        }

        // Then search filter
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else {
            return base
        }

        let lower = trimmedSearch.lowercased()

        return base.filter { quote in
            quote.text.lowercased().contains(lower) ||
            quote.author.lowercased().contains(lower) ||
            quote.source.lowercased().contains(lower)
        }
    }

    // MARK: - Actions

    private func handleResurface() {
        if let chosen = store.resurfaceQuote() {
            resurfacedQuote = chosen
            showingResurfaceSheet = true
        }
    }
}

// MARK: - Header Chrome (just the glass buttons)

struct HeaderChromeView: View {
    @Environment(\.colorScheme) private var colorScheme

    var onSettings: () -> Void
    var onResurface: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Button(action: onSettings) {
                glassCircle(systemName: "gearshape")
            }

            Spacer()

            Button(action: onResurface) {
                glassCircle(systemName: "sparkles", highlighted: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: - Glass button helper

    private func glassCircle(systemName: String, highlighted: Bool = false) -> some View {
        let highlightColor: Color = {
            if colorScheme == .dark {
                return Color(red: 0.78, green: 0.86, blue: 1.0)
                        } else {
                            return Color(red: 0.96, green: 0.53, blue: 0.72)
                        }
                    }()

                    return ZStack {
                        // base blur
                        Circle()
                            .fill(.ultraThinMaterial)

                        // subtle “sheen”
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.22 : 0.40),
                                        Color.white.opacity(0.06),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // soft border
                        Circle()
                            .stroke(
                                Color.white.opacity(colorScheme == .dark ? 0.35 : 0.20),
                                lineWidth: 0.9
                            )

                        // icon
                        Image(systemName: systemName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(highlighted ? highlightColor : .primary)
                    }
                    .frame(width: 40, height: 40)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.55 : 0.20),
                        radius: 8,
                        y: 3
                    )
                }
}

// MARK: - Bottom Glass Control Bar

struct BottomControlBar: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var searchText: String
    @Binding var showFavoritesOnly: Bool
    var onAddQuote: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            filterChip
            searchField
            addButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Filter chip (glass + blue edge)

    private var filterChip: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                showFavoritesOnly.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showFavoritesOnly ? "star.fill" : "line.3.horizontal")
                Text(showFavoritesOnly ? "Favorites" : "All")
            }
            .font(.system(.subheadline, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    // base blur
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)

                    // bright “sheen” on the top-left, fading out
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.20 : 0.35),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // soft blue edge (like before)
                    Capsule(style: .continuous)
                        .stroke(filterBorderGradient, lineWidth: 1)
                }
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.18),
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search field (glass pill)

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search quotes", text: $searchText)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.18 : 0.32),
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(
                        Color.white.opacity(colorScheme == .dark ? 0.28 : 0.16),
                        lineWidth: 0.9
                    )
            }
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.18),
            radius: 8,
            y: 4
        )
    }

    // MARK: - Add button (glass circle + pink edge)

    private var addButton: some View {
        Button(action: onAddQuote) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(12)
                .background(
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.22 : 0.38),
                                        Color.white.opacity(0.06),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Circle()
                            .stroke(addBorderGradient, lineWidth: 1.6)
                    }
                )
                .foregroundColor(.white)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.55 : 0.25),
                    radius: 9,
                    y: 4
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Gradients / Colors

    private var filterBorderGradient: LinearGradient {
        let colors: [Color]
        if colorScheme == .dark {
            colors = [
                Color(red: 0.65, green: 0.78, blue: 0.98),
                Color(red: 0.42, green: 0.60, blue: 0.92)
            ]
        } else {
            colors = [
                Color(red: 0.80, green: 0.88, blue: 1.00),
                Color(red: 0.64, green: 0.79, blue: 0.98)
            ]
        }
        return LinearGradient(
            colors: colors.map { $0.opacity(colorScheme == .dark ? 0.35 : 0.9) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var addBorderGradient: LinearGradient {
        let colors: [Color]
        if colorScheme == .dark {
            colors = [
                Color(red: 0.96, green: 0.73, blue: 0.72),
                Color(red: 0.80, green: 0.47, blue: 0.50)
            ]
        } else {
            colors = [
                Color(red: 0.99, green: 0.80, blue: 0.75),
                Color(red: 0.93, green: 0.55, blue: 0.55)
            ]
        }
        return LinearGradient(
            colors: colors.map { $0.opacity(colorScheme == .dark ? 0.45 : 0.95) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Resurface View

struct ResurfaceView: View {
    @Environment(\.colorScheme) private var colorScheme
    let quote: Quote

    var body: some View {
        let material: Material = colorScheme == .dark ? .ultraThinMaterial : .thinMaterial

        VStack(spacing: 24) {
            Text("A quote you loved")
                .font(.system(.headline, design: .rounded))

            QuoteCardView(quote: quote, onToggleFavorite: {})
                .padding(.horizontal)

            if let last = quote.lastResurfacedAt {
                Text("Last resurfaced: \(last.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.top, 40)
        .background(
            Rectangle()
                .fill(material)         // 👈 glassy layer
                .ignoresSafeArea()
        )
        .dynamicTypeSize(.small ... .accessibility3)
    }
}


// MARK: - Card View

struct QuoteCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let quote: Quote
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main quote content
            Text("“\(quote.text)”")
                .font(quoteFont())
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(quote.author.isEmpty ? "Unknown" : quote.author)
                .font(authorFont())
                .fontWeight(.semibold)

            Text(quote.source)
                .font(sourceFont())
                .foregroundStyle(.secondary)

            // Star at bottom-right
            HStack {
                Spacer()
                Button(action: onToggleFavorite) {
                    Image(systemName: quote.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(
                            quote.isFavorite
                            ? Color(red: 0.98, green: 0.88, blue: 0.45)  // pastel yellow
                            : Color.white.opacity(colorScheme == .dark ? 0.35 : 0.45)
                        )
                        .padding(4)   // small tap padding, no background circle
                }
            }
            .padding(.top, 6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors(for: quote.colorStyle),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.7 : 0.25),
            radius: 6,
            y: 3
        )
        .dynamicTypeSize(.small ... .accessibility3)
    }

    // Typography helpers

    private func quoteFont() -> Font {
        switch quote.fontStyle {
        case .standard:
            return .system(size: 22, weight: .semibold, design: .default)
        case .serif:
            return .system(size: 22, weight: .semibold, design: .serif)
        case .rounded:
            return .custom("AvenirNext-Medium", size: 22)
        }
    }

    private func authorFont() -> Font {
        switch quote.fontStyle {
        case .standard:
            return .system(size: 17, weight: .medium, design: .default)
        case .serif:
            return .system(size: 17, weight: .medium, design: .serif)
        case .rounded:
            return .custom("AvenirNext-DemiBold", size: 14)
        }
    }

    private func sourceFont() -> Font {
        switch quote.fontStyle {
        case .standard:
            return .system(size: 15, weight: .regular, design: .default)
        case .serif:
            return .system(size: 15, weight: .regular, design: .serif)
        case .rounded:
            return .custom("AvenirNext-Regular", size: 12)
        }
    }

    private func gradientColors(for style: PastelStyle) -> [Color] {
        let lightColors: [Color]
        switch style {
        case .mint:
            lightColors = [Color.mint.opacity(0.7), .white]
        case .blush:
            lightColors = [Color.pink.opacity(0.7), .white]
        case .lilac:
            lightColors = [Color.purple.opacity(0.6), .white]
        case .sky:
            lightColors = [Color.blue.opacity(0.5), .white]
        case .peach:
            lightColors = [Color.orange.opacity(0.6), .white]
        case .butter:
            lightColors = [Color.yellow.opacity(0.6), .white]
        }

        if colorScheme == .dark {
            return [
                lightColors[0].opacity(0.6),
                Color.black.opacity(0.7)
            ]
        } else {
            return lightColors
        }
    }
}

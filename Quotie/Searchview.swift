import SwiftUI

enum SourceCategory: String, CaseIterable, Identifiable {
    case books = "Books"
    case movies = "Movies"
    case podcasts = "Podcasts"
    case speeches = "Speeches"
    case articles = "Articles"
    case songs = "Songs"
    case misc = "Misc"

    var id: String { rawValue }
}

extension SourceCategory {

    func matches(source: String) -> Bool {
        let s = source.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return false }

        func hasAny(_ words: [String]) -> Bool {
            words.contains { s.contains($0) }
        }

        // lightweight heuristic so “Book titles” still count as books
        func looksLikeBookTitle() -> Bool {
            if s.contains("http") || s.contains(".com") || s.contains("www.") { return false }
            let blockers = ["podcast", "episode", "movie", "film", "song", "album", "track", "keynote", "talk", "ted", "tedx"]
            if hasAny(blockers) { return false }

            let words = s.split(separator: " ").map(String.init)
            return words.count >= 2 && words.count <= 8
        }

        switch self {
        case .books:
            if hasAny(["book", "novel", "chapter", "page", "kindle", "audiobook", "paperback", "hardcover"]) { return true }
            return looksLikeBookTitle()

        case .movies:
            return hasAny(["movie", "film", "cinema", "scene", "director", "screenplay", "netflix", "hulu", "disney", "hbo", "prime video"])

        case .podcasts:
            return hasAny(["podcast", "episode", "ep ", "ep.", "spotify", "apple podcasts", "overcast"])

        case .speeches:
            return hasAny(["keynote", "talk", "speech", "ted", "tedx", "lecture", "sermon"])

        case .articles:
            return hasAny(["article", "essay", "blog", "newsletter", "substack", "medium", "nyt", "guardian", "washington post", "the atlantic"])

        case .songs:
            return hasAny(["song", "lyrics", "album", "track", "single"])

        case .misc:
            return true
        }
    }
}

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var store: QuoteStore

    @State private var query: String = ""
    @State private var selectedQuote: Quote? = nil
    @State private var selectedCategory: SourceCategory? = nil

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        NavigationView {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        searchBar
                        sourcesSection

                        // ✅ If filtering/searching: show Results.
                        // ✅ Otherwise: show Recent Quotes.
                        if shouldShowResults {
                            resultsSection
                        } else {
                            recentQuotesSection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Search").font(.headline)
                }
            }
            .sheet(item: $selectedQuote) { quote in
                QuoteDetailView(quote: quote)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - UI

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search quotes, authors, sources…", text: $query)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 18, scheme: scheme)
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sources")
                .font(.headline)
                .foregroundStyle(DesignSystem.primaryText(scheme))

            let items: [(SourceCategory, String)] = [
                (.books, "book.closed"),
                (.songs, "music.note"),
                (.movies, "film"),
                (.podcasts, "mic")
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(items, id: \.0.id) { cat, icon in
                    let isSelected = (selectedCategory == cat)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            selectedCategory = isSelected ? nil : cat
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : DesignSystem.monsterPurple)

                            Text(cat.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isSelected ? .white : DesignSystem.primaryText(scheme))

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white.opacity(0.95))
                            }
                        }
                        .padding(12)
                        .liquidGlass(cornerRadius: 18, scheme: scheme)
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.30 : 0.22))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // ✅ 10 most recent quotes = last 10 appended, newest → oldest
    private var recentQuotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Quotes")
                .font(.headline)
                .foregroundStyle(DesignSystem.primaryText(scheme))

            let recent = Array(store.quotes.suffix(10)).reversed()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(recent), id: \.id) { q in
                    MasonryQuoteCard(quote: q) {
                        store.toggleFavorite(q)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedQuote = q }
                }
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Results")
                    .font(.headline)
                    .foregroundStyle(DesignSystem.primaryText(scheme))

                Spacer()

                if let selectedCategory {
                    Text(selectedCategory.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.secondaryText(scheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .liquidGlass(cornerRadius: 14, scheme: scheme)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                self.selectedCategory = nil
                            }
                        }
                }
            }

            VStack(spacing: 10) {
                ForEach(activeFilteredQuotes.prefix(24)) { q in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("“\(q.text)”")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DesignSystem.primaryText(scheme))
                            .lineLimit(3)

                        HStack(spacing: 10) {
                            if !q.author.isEmpty {
                                Text(q.author)
                                    .font(.caption)
                                    .foregroundStyle(DesignSystem.secondaryText(scheme))
                            }
                            if !q.source.isEmpty {
                                Text("• \(q.source)")
                                    .font(.caption)
                                    .foregroundStyle(DesignSystem.secondaryText(scheme))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .liquidGlass(cornerRadius: 18, scheme: scheme)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedQuote = q }
                }
            }
        }
    }

    // MARK: - Filtering Logic

    private var shouldShowResults: Bool {
        let hasQuery = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasQuery || selectedCategory != nil
    }

    private var activeFilteredQuotes: [Quote] {
        var base = store.quotes

        if let selectedCategory {
            base = base.filter { selectedCategory.matches(source: $0.source) }
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }

        let lower = trimmed.lowercased()
        return base.filter {
            $0.text.lowercased().contains(lower) ||
            $0.author.lowercased().contains(lower) ||
            $0.source.lowercased().contains(lower)
        }
    }
}

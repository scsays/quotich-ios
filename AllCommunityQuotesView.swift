import SwiftUI

struct AllCommunityQuotesView: View {
    @EnvironmentObject private var store: QuoteStore
    @Environment(\.dismiss) private var dismiss

    let scheme: ColorScheme

    enum Filter: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case mostFavorited = "Most Liked"
        case liked = "Liked"
        case oldest = "Oldest"
        case surprise = "Surprise Me"

        var id: String { rawValue }

        var emptyMessage: String {
            switch self {
            case .liked:
                return "No liked community quotes yet. Tap the heart on quotes you want to find again later."
            case .surprise:
                return "No surprise quote found yet."
            default:
                return "No community quotes found."
            }
        }
    }

    @State private var filter: Filter = .newest
    @State private var searchText = ""

    @State private var quotes: [CommunityFeedQuote] = []
    @State private var isLoading = false
    @State private var error: String? = nil

    @State private var offset: Int = 0
    private let pageSize: Int = 30

    @State private var selectedQuote: CommunityFeedQuote? = nil
    @State private var showSubmitSheet = false
    @State private var submitError: String? = nil
    @State private var showSubmitErrorAlert = false

    @AppStorage("likedCommunityQuoteIDs") private var likedCommunityQuoteIDsRaw: String = ""
    @State private var likedCommunityQuoteIDs: Set<String> = []
    @State private var addedCommunityIDs: Set<UUID> = []

    private var displayedQuotes: [CommunityFeedQuote] {
        var base = quotes

        if filter == .liked {
            base = base.filter { likedCommunityQuoteIDs.contains($0.id.uuidString) }
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }

        let lower = trimmed.lowercased()
        return base.filter {
            $0.text.lowercased().contains(lower) ||
            ($0.author ?? "").lowercased().contains(lower) ||
            ($0.source ?? "").lowercased().contains(lower)
        }
    }

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 14) {
                header
                searchBar
                filterRow
                content
            }
            .padding(.top, 10)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") { dismiss() }
            }
            ToolbarItem(placement: .principal) {
                Text("Community").font(.headline)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSubmitSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Submit Quote")
            }
        }
        .sheet(item: $selectedQuote) { quote in
            CommunityQuoteDetailSheet(
                quote: quote,
                scheme: scheme,
                isLiked: likedCommunityQuoteIDs.contains(quote.id.uuidString),
                isAdded: addedCommunityIDs.contains(quote.id),
                onToggleLike: { toggleLike(for: quote) },
                onAdd: { addToMyQuotes(quote) }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSubmitSheet) {
            SubmitCommunityQuoteSheet(
                scheme: scheme,
                onSubmit: { text, author, source in
                    submitQuote(text: text, author: author, source: source)
                },
                onCancel: { showSubmitSheet = false }
            )
            .presentationDetents([.medium, .large])
        }
        .alert("Couldn’t submit quote", isPresented: $showSubmitErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(submitError ?? "Unknown error.")
        }
        .onAppear {
            likedCommunityQuoteIDs = decodeLikedIDs(likedCommunityQuoteIDsRaw)
            load(reset: true)
        }
        .onChange(of: filter) { _ in load(reset: true) }
        .onReceive(NotificationCenter.default.publisher(for: .communityFeedDidChange)) { _ in
            load(reset: true)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Explore community quotes")
                .font(.title3.weight(.bold))
                .foregroundStyle(DesignSystem.primaryText(scheme))

            Text("Search by theme, author, or source. Save favorites to find them again, or add them back to your own feed.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search themes, authors, sources…", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 18, scheme: scheme)
        .padding(.horizontal, 16)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Filter.allCases) { f in
                    Button {
                        filter = f
                    } label: {
                        Text(f.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(filter == f ? .white : DesignSystem.primaryText(scheme))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule().fill(filter == f
                                               ? DesignSystem.monsterPurple
                                               : Color.white.opacity(scheme == .dark ? 0.08 : 0.65))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && quotes.isEmpty {
            Spacer()
            ProgressView()
            Spacer()
        } else if let error, quotes.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Text(error)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Retry") { load(reset: true) }
                    .buttonStyle(.borderedProminent)
                    .tint(DesignSystem.monsterPurple)
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if displayedQuotes.isEmpty {
                        emptyState
                    } else {
                        ForEach(displayedQuotes) { quote in
                            communityQuoteRow(quote)
                        }
                    }

                    if filter != .surprise && filter != .liked && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        loadMoreButton
                    }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
            .refreshable { load(reset: true) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: filter == .liked ? "heart" : "quote.bubble")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DesignSystem.monsterPurple)

            Text(filter.emptyMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .liquidGlass(cornerRadius: 22, scheme: scheme)
    }

    private var loadMoreButton: some View {
        Button {
            load(reset: false)
        } label: {
            HStack {
                if isLoading { ProgressView().tint(.white) }
                Text(isLoading ? "Loading…" : "Load More")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DesignSystem.monsterPurple)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .padding(.top, 6)
    }

    private func communityQuoteRow(_ quote: CommunityFeedQuote) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            QuoteCardView(
                quote: quote.asLocalQuote(),
                onToggleFavorite: { toggleLike(for: quote) },
                isHighlighted: addedCommunityIDs.contains(quote.id)
            )
            .onTapGesture { selectedQuote = quote }

            HStack(spacing: 12) {
                Button { toggleLike(for: quote) } label: {
                    Label(
                        "\(quote.favoritesCount + (likedCommunityQuoteIDs.contains(quote.id.uuidString) && !quote.isFavorited ? 1 : 0))",
                        systemImage: likedCommunityQuoteIDs.contains(quote.id.uuidString) ? "heart.fill" : "heart"
                    )
                }
                .buttonStyle(.bordered)
                .tint(DesignSystem.monsterPurple)

                Button { addToMyQuotes(quote) } label: {
                    Label(addedCommunityIDs.contains(quote.id) ? "Added" : "Add", systemImage: addedCommunityIDs.contains(quote.id) ? "checkmark" : "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.monsterPurple)
                .disabled(addedCommunityIDs.contains(quote.id))

                Spacer()

                if let source = quote.source, !source.isEmpty {
                    Text(source)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .liquidGlass(cornerRadius: 24, scheme: scheme)
    }

    private func load(reset: Bool) {
        if isLoading { return }

        if reset {
            offset = 0
            quotes = []
        }

        isLoading = true
        error = nil

        Task {
            do {
                if filter == .surprise {
                    let one = try await CommunityFeedService.shared.fetchRandomQuote()
                    await MainActor.run {
                        quotes = [one]
                        isLoading = false
                    }
                    return
                }

                let sort: CommunityFeedService.Sort = {
                    switch filter {
                    case .newest, .liked: return .new
                    case .oldest: return .old
                    case .mostFavorited: return .top
                    case .surprise: return .new
                    }
                }()

                let rows = try await CommunityFeedService.shared.fetchFeed(
                    limit: pageSize,
                    offset: offset,
                    sort: sort
                )

                await MainActor.run {
                    if reset {
                        quotes = rows
                    } else {
                        quotes.append(contentsOf: rows)
                    }
                    offset += rows.count
                    isLoading = false
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = "Couldn’t load community quotes. (\(error.localizedDescription))"
                }
            }
        }
    }

    private func submitQuote(text: String, author: String?, source: String?) {
        Task {
            do {
                try await CommunityFeedService.shared.submitQuote(text: text, author: author, source: source)
                await MainActor.run {
                    showSubmitSheet = false
                    filter = .newest
                    load(reset: true)
                }
            } catch {
                await MainActor.run {
                    submitError = error.localizedDescription
                    showSubmitErrorAlert = true
                }
            }
        }
    }

    private func addToMyQuotes(_ quote: CommunityFeedQuote) {
        store.addQuote(
            text: quote.text,
            author: quote.author ?? "",
            source: quote.source ?? "",
            colorStyle: .mint,
            fontStyle: .rounded
        )

        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            _ = addedCommunityIDs.insert(quote.id)
        }
    }

    private func toggleLike(for quote: CommunityFeedQuote) {
        let idString = quote.id.uuidString

        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            if likedCommunityQuoteIDs.contains(idString) {
                likedCommunityQuoteIDs.remove(idString)
            } else {
                likedCommunityQuoteIDs.insert(idString)
            }
        }

        likedCommunityQuoteIDsRaw = encodeLikedIDs(likedCommunityQuoteIDs)
    }

    private func encodeLikedIDs(_ set: Set<String>) -> String {
        set.sorted().joined(separator: "|")
    }

    private func decodeLikedIDs(_ raw: String) -> Set<String> {
        guard !raw.isEmpty else { return [] }
        return Set(raw.split(separator: "|").map(String.init))
    }
}

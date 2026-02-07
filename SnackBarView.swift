import SwiftUI
import Combine

// MARK: - Snack Models

enum SnackSource: String, CaseIterable, Identifiable {
    case books = "Books"
    case songs = "Songs"
    case movies = "Movies"
    case podcasts = "Podcasts"
    case community = "Community"

    var id: String { rawValue }
}

struct SnackQuote: Identifiable, Equatable {
    let id: String          // deterministic
    let text: String
    let author: String
    let origin: String
    let source: SnackSource

    init(text: String, author: String, origin: String, source: SnackSource) {
        self.text = text
        self.author = author
        self.origin = origin
        self.source = source
        self.id = "\(source.rawValue)|\(author)|\(origin)|\(text)"
    }
}

// MARK: - Snack Bar View

struct SnackBarView: View {
    @EnvironmentObject private var store: QuoteStore
    @Environment(\.colorScheme) private var scheme

    var onBack: () -> Void

    @State private var selectedSource: SnackSource? = nil

    // Snack overlay (existing)
    @State private var expandedSnack: SnackQuote? = nil

    // Community detail sheet
    @State private var selectedCommunityQuote: CommunityFeedQuote? = nil

    // ✅ All Community Quotes screen
    @State private var showAllCommunityQuotes = false

    // Existing snack logic
    private let allSnacks: [SnackQuote] = SnackQuoteLibrary.all
    @State private var recommendedSnacks: [SnackQuote] = []
    @State private var addedSnackIDs: Set<String> = []
    @State private var dismissedSnackIDs: Set<String> = []

    // Community feed
    @State private var communityQuotes: [CommunityFeedQuote] = []
    @State private var isLoadingCommunity = false
    @State private var communityError: String? = nil

    // Submit Quote
    @State private var showSubmitSheet = false
    @State private var submitError: String? = nil
    @State private var showSubmitErrorAlert = false

    // Likes (local persistence)
    @AppStorage("likedCommunityQuoteIDs") private var likedCommunityQuoteIDsRaw: String = ""
    @State private var likedCommunityQuoteIDs: Set<String> = []

    // Add-to-my-quotes feedback for community quotes
    @State private var addedCommunityIDs: Set<UUID> = []

    // Scroll effects
    @State private var scrollY: CGFloat = 0

    private var displayedSnacks: [SnackQuote] {
        guard selectedSource != .community else { return [] }

        let base: [SnackQuote]
        if let selectedSource {
            base = allSnacks.filter { $0.source == selectedSource }
        } else {
            base = recommendedSnacks
        }

        return base.filter { !dismissedSnackIDs.contains($0.id) }
    }

    private var headerT: CGFloat {
        let start: CGFloat = 10
        let end: CGFloat = 140
        let t = (scrollY - start) / (end - start)
        return min(max(t, 0), 1)
    }

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        headerAndSources
                            .padding(.top, 6)

                        // MARK: - Snack Quotes
                        if selectedSource != .community {
                            LazyVStack(spacing: 14) {
                                ForEach(displayedSnacks) { snack in
                                    SnackQuoteCard(
                                        snack: snack,
                                        scheme: scheme,
                                        isAdded: addedSnackIDs.contains(snack.id),
                                        onExpand: { expandedSnack = snack },
                                        onQuickAdd: { quickAddSnack(snack) }
                                    )
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                            .animation(.spring(response: 0.35, dampingFraction: 0.92), value: displayedSnacks)
                        }

                        // MARK: - Community Quotes
                        if selectedSource == .community {
                            communitySection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y
                } action: { _, newOffset in
                    scrollY = newOffset
                }
                .onAppear {
                    if recommendedSnacks.isEmpty {
                        recommendedSnacks = Array(allSnacks.shuffled().prefix(10))
                    }
                    likedCommunityQuoteIDs = decodeLikedIDs(likedCommunityQuoteIDsRaw)

                    // ✅ Always refresh community once when SnackBar appears
                    loadCommunity(force: true)
                }
                .onReceive(NotificationCenter.default.publisher(for: .communityFeedDidChange)) { _ in
                    loadCommunity(force: true)
                }

                // Expanded snack overlay (existing)
                if let snack = expandedSnack {
                    SnackExpandedView(
                        snack: snack,
                        onAdd: {
                            quickAddSnack(snack)
                            expandedSnack = nil
                        },
                        onBack: { expandedSnack = nil }
                    )
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { onBack() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Snack Bar").font(.headline)
                }
            }

            // ✅ Push to All Community Quotes screen
            .navigationDestination(isPresented: $showAllCommunityQuotes) {
                AllCommunityQuotesView(scheme: scheme)
                    .environmentObject(store)
            }

            // Submit Quote sheet
            .sheet(isPresented: $showSubmitSheet) {
                SubmitCommunityQuoteSheet(
                    scheme: scheme,
                    onSubmit: { text, author, source in
                        Task {
                            do {
                                try await CommunityFeedService.shared.submitQuote(
                                    text: text,
                                    author: author,
                                    source: source
                                )

                                await MainActor.run { showSubmitSheet = false }

                                // ✅ Force refresh (submitQuote already posts .communityFeedDidChange)
                                loadCommunity(force: true)

                            } catch {
                                await MainActor.run {
                                    submitError = error.localizedDescription
                                    showSubmitErrorAlert = true
                                }
                            }
                        }
                    },
                    onCancel: { showSubmitSheet = false }
                )
                .presentationDetents([.medium, .large])
            }

            // Community detail sheet
            .sheet(item: $selectedCommunityQuote) { quote in
                CommunityQuoteDetailSheet(
                    quote: quote,
                    scheme: scheme,
                    isLiked: likedCommunityQuoteIDs.contains(quote.id.uuidString),
                    isAdded: addedCommunityIDs.contains(quote.id),
                    onToggleLike: { toggleLike(for: quote) },
                    onAdd: { quickAddCommunity(quote) }
                )
                .presentationDetents([.medium, .large])
            }

            .alert("Couldn’t submit quote", isPresented: $showSubmitErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(submitError ?? "Unknown error.")
            }
        }
    }

    // MARK: - Community Add (with animation)

    private func quickAddCommunity(_ quote: CommunityFeedQuote) {
        addSnack(quote.asSnackQuote)

        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            _ = addedCommunityIDs.insert(quote.id)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.92)) {
                    _ = addedCommunityIDs.remove(quote.id)
                }
            }
        }
    }

    // MARK: - Community Section

    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Community")
                    .font(.headline)
                    .foregroundStyle(DesignSystem.primaryText(scheme))

                Spacer()

                Button("Submit Quote") {
                    showSubmitSheet = true
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.monsterPurple)
            }

            if isLoadingCommunity {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.top, 18)

            } else if let communityError {
                Text(communityError)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 18)

                Button("Retry") { loadCommunity(force: true) }
                    .buttonStyle(.borderedProminent)
                    .tint(DesignSystem.monsterPurple)

            } else {
                LazyVStack(spacing: 14) {

                    // ✅ Only show 10 most recent here
                    ForEach(Array(communityQuotes.prefix(10))) { quote in
                        QuoteCardView(
                            quote: quote.asLocalQuote(),
                            onToggleFavorite: { toggleLike(for: quote) }
                        )
                        .onTapGesture {
                            selectedCommunityQuote = quote
                        }
                        .contextMenu {
                            Button("Add to My Quotes") { quickAddCommunity(quote) }
                            Button(likedCommunityQuoteIDs.contains(quote.id.uuidString) ? "Unlike" : "Like") {
                                toggleLike(for: quote)
                            }
                        }
                    }

                    // ✅ Full-width CTA to All Community Quotes screen
                    Button {
                        showAllCommunityQuotes = true
                    } label: {
                        Text("All Community Quotes")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DesignSystem.monsterPurple)
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            }
        }
    }

    // MARK: - Header + Sources

    private var headerAndSources: some View {
        let t = headerT
        let blur = 10 * t
        let fade = 1 - Double(0.55 * t)
        let lift = -22 * t

        return VStack(alignment: .leading, spacing: 12) {
            header
            sourcesGrid
        }
        .opacity(fade)
        .blur(radius: blur)
        .offset(y: lift)
        .animation(.easeOut(duration: 0.18), value: t)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(selectedSource == .community ? "Community Feed" : "Recommended Quotes")
                .font(.title3.weight(.bold))

            Text(selectedSource == .community ? "Public read • Auth-required write" : "Quick bites for the soul")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // ✅ Sources: 2-column grid + a full-width Community tile
    private var sourcesGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sources")
                .font(.headline)
                .foregroundStyle(DesignSystem.primaryText(scheme))

            let gridItems: [(SnackSource, String)] = [
                (.books, "book.closed"),
                (.songs, "music.note"),
                (.movies, "film"),
                (.podcasts, "mic")
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(gridItems, id: \.0.id) { src, icon in
                    sourceTileButton(source: src, icon: icon, fullWidth: false)
                }
            }

            // ✅ Full-width Community button (solid purple when selected)
            sourceTileButton(source: .community, icon: "person.3.fill", fullWidth: true)
        }
    }

    private func sourceTileButton(source src: SnackSource, icon: String, fullWidth: Bool) -> some View {
        let isSelected = (selectedSource == src)

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                selectedSource = isSelected ? nil : src
            }
            if src == .community && !isSelected {
                loadCommunity(force: true)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : DesignSystem.monsterPurple)

                Text(src.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : DesignSystem.primaryText(scheme))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
            .padding(12)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected
                          ? AnyShapeStyle(DesignSystem.monsterPurple)
                          : AnyShapeStyle(.ultraThinMaterial))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(scheme == .dark ? 0.10 : 0.18), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Snack Add Logic

    private func addSnack(_ snack: SnackQuote) {
        store.addQuote(
            text: snack.text,
            author: snack.author,
            source: snack.origin,
            colorStyle: .mint,
            fontStyle: .rounded
        )
    }

    private func quickAddSnack(_ snack: SnackQuote) {
        guard !addedSnackIDs.contains(snack.id) else { return }

        addSnack(snack)

        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            _ = addedSnackIDs.insert(snack.id)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.92)) {
                    _ = dismissedSnackIDs.insert(snack.id)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    _ = addedSnackIDs.remove(snack.id)
                }
            }
        }
    }

    // MARK: - Community Loader

    private func loadCommunity(force: Bool) {
        if isLoadingCommunity { return }
        if !force && !communityQuotes.isEmpty { return }

        isLoadingCommunity = true
        communityError = nil

        Task {
            do {
                let rows = try await CommunityFeedService.shared.fetchFeed(limit: 30, offset: 0, sort: .new)
                await MainActor.run {
                    communityQuotes = rows
                    isLoadingCommunity = false
                }
            } catch {
                await MainActor.run {
                    isLoadingCommunity = false
                    communityError = "Couldn’t load the community feed. (\(error.localizedDescription))"
                }
            }
        }
    }

    // MARK: - Likes (local)

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

// MARK: - Small helpers

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Snack Quote Card

struct SnackQuoteCard: View {
    let snack: SnackQuote
    let scheme: ColorScheme
    let isAdded: Bool
    let onExpand: () -> Void
    let onQuickAdd: () -> Void

    var body: some View {
        Button(action: onExpand) {
            VStack(alignment: .leading, spacing: 10) {
                Text("“\(snack.text)”")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DesignSystem.primaryText(scheme))

                Text("— \(snack.author), *\(snack.origin)*")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.secondaryText(scheme))

                HStack {
                    Spacer()
                    Button(action: onQuickAdd) {
                        Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(isAdded ? .green : DesignSystem.monsterPurple)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(14)
            .liquidGlass(cornerRadius: 22, scheme: scheme)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Submit Quote Sheet

struct SubmitCommunityQuoteSheet: View {
    let scheme: ColorScheme
    let onSubmit: (_ text: String, _ author: String?, _ source: String?) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""
    @State private var author: String = ""
    @State private var source: String = ""

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quote") {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                }

                Section("Optional") {
                    TextField("Author", text: $author)
                    TextField("Source (book, speech, etc.)", text: $source)
                }

                Section {
                    Button("Submit") {
                        onSubmit(
                            text.trimmingCharacters(in: .whitespacesAndNewlines),
                            author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : author,
                            source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : source
                        )
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Submit Quote")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
            .tint(DesignSystem.monsterPurple)
        }
    }
}

// MARK: - Expanded Snack View

struct SnackExpandedView: View {
    @Environment(\.colorScheme) private var scheme

    let snack: SnackQuote
    let onAdd: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onBack() }

            VStack(spacing: 18) {
                Text("“\(snack.text)”")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(scheme == .dark ? .white : .black)

                Text("— \(snack.author)\n\(snack.origin)")
                    .font(.callout)
                    .foregroundStyle((scheme == .dark ? Color.white : Color.black).opacity(0.75))
                    .multilineTextAlignment(.center)

                HStack(spacing: 14) {
                    Button("Back", action: onBack)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((scheme == .dark ? Color.white : Color.black).opacity(0.10))
                        .cornerRadius(14)

                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.monsterPurple)
                            .cornerRadius(14)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(scheme == .dark ? Color.black.opacity(0.78) : Color.white.opacity(0.94))
                    .shadow(radius: 18, y: 10)
            )
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Community Quote Detail Sheet

struct CommunityQuoteDetailSheet: View {
    let quote: CommunityFeedQuote
    let scheme: ColorScheme
    let isLiked: Bool
    let isAdded: Bool
    let onToggleLike: () -> Void
    let onAdd: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 10)

                QuoteCardView(
                    quote: quote.asLocalQuote(),
                    onToggleFavorite: onToggleLike,
                    isHighlighted: true
                )
                .padding(.horizontal, 18)

                HStack {
                    Button { dismiss() } label: {
                        SnackCircleActionButton(systemName: "xmark", size: 46, filled: false, disabled: false)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button { onToggleLike() } label: {
                        SnackCircleActionButton(systemName: isLiked ? "heart.fill" : "heart", size: 58, filled: true, disabled: false)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button { onAdd() } label: {
                        SnackCircleActionButton(systemName: isAdded ? "checkmark" : "plus", size: 46, filled: true, disabled: isAdded)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                    .disabled(isAdded)
                }
                .padding(.horizontal, 22)

                Spacer(minLength: 18)
            }
        }
    }
}

private struct SnackCircleActionButton: View {
    @Environment(\.colorScheme) private var scheme

    let systemName: String
    let size: CGFloat
    let filled: Bool
    let disabled: Bool

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: filled ? 20 : 18, weight: .heavy))
            .foregroundStyle(filled ? .white : DesignSystem.primaryText(scheme))
            .frame(width: size, height: size)
            .background(Circle().fill(backgroundFill))
            .overlay(
                Circle().stroke(Color.white.opacity(scheme == .dark ? 0.12 : 0.22), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.35 : 0.12), radius: 14, y: 8)
            .opacity(disabled ? 0.55 : 1.0)
    }

    private var backgroundFill: AnyShapeStyle {
        filled ? AnyShapeStyle(DesignSystem.monsterPurple) : AnyShapeStyle(.ultraThinMaterial)
    }
}

// MARK: - Community mapping

extension CommunityFeedQuote {
    var asSnackQuote: SnackQuote {
        SnackQuote(
            text: text,
            author: (author?.isEmpty == false ? author! : "Anonymous"),
            origin: (source?.isEmpty == false ? source! : "Community"),
            source: .community
        )
    }
}

import SwiftUI

// MARK: - Snack Models

enum SnackSource: String, CaseIterable, Identifiable {
    case books = "Books"
    case songs = "Songs"
    case movies = "Movies"
    case podcasts = "Podcasts"

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
    @State private var expandedSnack: SnackQuote? = nil
    @State private var recommendedSnacks: [SnackQuote] = []

    // Must match SnackQuote.id type (String)
    @State private var addedSnackIDs: Set<String> = []
    @State private var dismissedSnackIDs: Set<String> = []

    // Scroll effects
    @State private var scrollY: CGFloat = 0

    private let allSnacks: [SnackQuote] = SnackQuoteLibrary.all

    private var displayedSnacks: [SnackQuote] {
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

        NavigationView {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        headerAndSources
                            .padding(.top, 6)

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
                }

                if let snack = expandedSnack {
                    SnackExpandedView(
                        snack: snack,
                        onAdd: {
                            quickAddSnack(snack)
                            expandedSnack = nil
                        },
                        onBack: {
                            expandedSnack = nil
                        }
                    )
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { onBack() }   // ✅ matches Search
                }
                ToolbarItem(placement: .principal) {
                    Text("Snack Bar").font(.headline) // ✅ matches Search
                }
            }
        }
    }

    // MARK: - Header + Sources (scroll blur/fade)

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
            Text("Recommended Quotes")
                .font(.title3.weight(.bold))

            Text("Quick bites for the soul")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // ✅ Matches SearchView’s 2x2 source layout
    private var sourcesGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sources")
                .font(.headline)
                .foregroundStyle(DesignSystem.primaryText(scheme))

            let items: [(SnackSource, String)] = [
                (.books, "book.closed"),
                (.songs, "music.note"),
                (.movies, "film"),
                (.podcasts, "mic")
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(items, id: \.0.id) { src, icon in
                    let isSelected = (selectedSource == src)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            selectedSource = isSelected ? nil : src
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

    // MARK: - Add Logic

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

        // 1) show checkmark
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            addedSnackIDs.insert(snack.id)
        }

        // 2) brief pause, then slide out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.92)) {
                dismissedSnackIDs.insert(snack.id)
            }

            // 3) cleanup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                addedSnackIDs.remove(snack.id)
            }
        }
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
                    .buttonStyle(.borderless) // ✅ prevents the outer card tap
                }
            }
            .padding(14)
            .liquidGlass(cornerRadius: 22, scheme: scheme)
        }
        .buttonStyle(.plain)
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

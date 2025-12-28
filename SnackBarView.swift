import SwiftUI

// MARK: - Snack Models

enum SnackSource: String, CaseIterable {
    case books = "Books"
    case songs = "Songs"
    case movies = "Movies"
    case podcasts = "Podcasts"
}

struct SnackQuote: Identifiable {
    let id = UUID()
    let text: String
    let author: String
    let origin: String
    let source: SnackSource
}

// MARK: - Snack Bar View

struct SnackBarView: View {
    @EnvironmentObject private var store: QuoteStore
    @Environment(\.colorScheme) private var scheme

    /// Snack Bar is presented as a fullScreenCover in your current setup,
    /// so `onBack` should dismiss that cover.
    var onBack: () -> Void

    @State private var selectedSource: SnackSource? = nil
    @State private var expandedSnack: SnackQuote? = nil
    @State private var recommendedSnacks: [SnackQuote] = []

    // Scroll effects
    @State private var scrollY: CGFloat = 0

    private let allSnacks: [SnackQuote] = SnackQuoteLibrary.all

    private var displayedSnacks: [SnackQuote] {
        if let selectedSource {
            return allSnacks.filter { $0.source == selectedSource }
        } else {
            return recommendedSnacks
        }
    }

    // 0 = fully visible header, 1 = faded/blurred header state
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
                    VStack(spacing: 14) {

                        headerAndSources
                            .padding(.top, 6)

                        LazyVStack(spacing: 14) {
                            ForEach(displayedSnacks) { snack in
                                SnackQuoteCard(
                                    snack: snack,
                                    scheme: scheme,
                                    onExpand: { expandedSnack = snack },
                                    onQuickAdd: { addSnack(snack) }
                                )
                            }
                        }
                        .padding(.top, 6)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
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
                            addSnack(snack)
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
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onBack()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Snack Bar")
                        .font(.title3.weight(.bold))
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

        return VStack(spacing: 14) {
            header
            sourcePicker
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
                .font(.callout)               // ✅ slightly larger than subheadline
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }

    // MARK: - Sources (stacked like Search)

    private var sourcePicker: some View {
        VStack(spacing: 12) {
            ForEach(SnackSource.allCases, id: \.self) { source in
                let isSelected = (selectedSource == source)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        selectedSource = isSelected ? nil : source
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: source))
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 34)

                        Text(source.rawValue)
                            .font(.headline)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(DesignSystem.monsterPurple)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(DesignSystem.primaryText(scheme))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .liquidGlass(cornerRadius: 22, scheme: scheme)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(DesignSystem.monsterPurple.opacity(0.35), lineWidth: 1.5)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func icon(for source: SnackSource) -> String {
        switch source {
        case .books: return "book.closed.fill"
        case .songs: return "music.note"
        case .movies: return "film.fill"
        case .podcasts: return "mic.fill"
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
}

// MARK: - Snack Quote Card

struct SnackQuoteCard: View {
    let snack: SnackQuote
    let scheme: ColorScheme
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
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(DesignSystem.monsterPurple)
                    }
                    .buttonStyle(.plain)
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
            // ✅ Dim background (tap to close)
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

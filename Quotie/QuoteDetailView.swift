import SwiftUI
import UIKit   // needed for UIImage & UIActivityViewController

#if canImport(WidgetKit)
import WidgetKit
#endif

struct QuoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    

    @ObservedObject var store: QuoteStore
    let originalQuote: Quote

    // Local editable copies
    @State private var text: String
    @State private var author: String
    @State private var source: String
    @State private var colorStyle: PastelStyle
    @State private var fontStyle: FontStyle
    @State private var isFavorite: Bool

    @State private var isEditing = false
    @State private var hasDeleted = false

    // Sharing
    @State private var shareImage: UIImage?
    @State private var isShowingShareSheet = false

    init(store: QuoteStore, quote: Quote) {
        self.store = store
        self.originalQuote = quote

        _text       = State(initialValue: quote.text)
        _author     = State(initialValue: quote.author)
        _source     = State(initialValue: quote.source)
        _colorStyle = State(initialValue: quote.colorStyle)
        _fontStyle  = State(initialValue: quote.fontStyle)
        _isFavorite = State(initialValue: quote.isFavorite)
    }

    var body: some View {
        let base = colorScheme == .dark ? darkPaperBackground : lightPaperBackground
        let cardColors = gradientColors(for: colorStyle)

        ZStack {
            // Base paper
            base.ignoresSafeArea()

            // Full-screen color-matched gradient
            LinearGradient(
                colors: [
                    cardColors.first?.opacity(colorScheme == .dark ? 0.45 : 0.65) ?? base,
                    base.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Hero card stays at the top in BOTH modes
                QuoteCardView(
                    quote: previewQuote,
                    onToggleFavorite: { toggleFavorite() }
                )
                .padding(.horizontal)

                if isEditing {
                    editingControls        // fields, color, font, delete, Done
                } else {
                    viewControls           // Close / Edit / Share it
                }

                Spacer()
            }
            .padding(.top, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { }
        .sheet(isPresented: $isShowingShareSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .onDisappear {
            // Auto-save only if editing and not deleted
            if isEditing && !hasDeleted {
                saveEdits()
            }
        }
    }
    /// Generic outline-only glassy button used for Close / Edit / Share
    private func outlinedControl(
        title: String,
        tint: LinearGradient,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(.primary)
                .background(Color.clear)   // let gradient background show through
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(tint, lineWidth: 1.6)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - VIEW MODE (card + Close/Edit/Share under it)

    private var viewControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                outlinedControl(
                    title: "Close",
                    tint: filterChipGradient   // pastel blue, same as main filter chip
                ) {
                    dismiss()
                }
                outlinedControl(
                    title: "Use in Widget",
                    tint: filterChipGradient
                ) {
                    sendPreviewQuoteToWidget()
                }

                outlinedControl(
                    title: "Edit",
                    tint: filterChipGradient
                ) {
                    isEditing = true
                }
            }

            outlinedControl(
                title: "Share It",
                tint: shareBorderGradient    // pastel pink, like + button
            ) {
                shareCurrentQuote()
            }
        }
        
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - EDIT MODE (fields under the card, card fixed at top)

    private var editingControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote label + editor
            VStack(alignment: .leading, spacing: 6) {
                Text("Quote")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 140)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(fieldBackground)
                    )
            }

            // Author / Source
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Author")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.85))
                    TextField("Author", text: $author)
                        .textInputAutocapitalization(.words)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(fieldBackground)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Source")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.85))
                    TextField("Book, talk, etc.", text: $source)
                        .textInputAutocapitalization(.words)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(fieldBackground)
                        )
                }
            }

            // Color picker row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PastelStyle.allCases, id: \.self) { style in
                        let colors = gradientColors(for: style)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(
                                        Color.white.opacity(style == colorStyle ? 0.9 : 0),
                                        lineWidth: 2
                                    )
                            )
                            .onTapGesture {
                                colorStyle = style
                            }
                    }
                }
                .padding(.vertical, 4)
            }

            // Font style + Delete
            HStack(spacing: 10) {
                Picker("Style", selection: $fontStyle) {
                    Text("Modern").tag(FontStyle.standard)
                    Text("Serif").tag(FontStyle.serif)
                    Text("Personal").tag(FontStyle.rounded)
                }
                .pickerStyle(.segmented)

                Button(role: .destructive) {
                    hasDeleted = true
                    store.delete(originalQuote)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.99, green: 0.80, blue: 0.75),
                                            Color(red: 0.93, green: 0.55, blue: 0.55)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                }
            }

            // Done button at bottom of controls
            Button {
                saveEdits()
                isEditing = false
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.10)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    // MARK: - Sharing

    private func shareCurrentQuote() {
        guard #available(iOS 16.0, *) else {
            // Fallback: share plain text if you ever support < iOS 16
            shareImage = nil
            isShowingShareSheet = true
            return
        }

        // Render the quote card into an image
        let renderer = ImageRenderer(
            content:
                QuoteCardView(quote: previewQuote, onToggleFavorite: {})
                    .padding()
                    .background(Color.clear)
        )
        renderer.scale = displayScale

        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            isShowingShareSheet = true
        }
    }

    // MARK: - Derived quote for preview

    private var previewQuote: Quote {
        Quote(
            id: originalQuote.id,
            text: text,
            author: author,
            source: source,
            isFavorite: isFavorite,
            colorStyle: colorStyle,
            timesResurfaced: originalQuote.timesResurfaced,
            lastResurfacedAt: originalQuote.lastResurfacedAt,
            fontStyle: fontStyle
        )
    }

    private func sendPreviewQuoteToWidget() {
        let q = previewQuote

        let shared = SharedQuote(
            id: q.id,
            text: q.text,
            author: q.author.isEmpty ? nil : q.author,
            createdAt: Date(),
            colorStyleRaw: q.colorStyle.rawValue   // <- pass the PastelStyle as a String
        )

        SharedQuoteStore.saveLatestQuote(shared)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    private func saveEdits() {
        guard !hasDeleted else { return }

        let trimmedText   = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)

        let updated = Quote(
            id: originalQuote.id,
            text: trimmedText.isEmpty ? originalQuote.text : trimmedText,
            author: trimmedAuthor,
            source: trimmedSource,
            isFavorite: isFavorite,
            colorStyle: colorStyle,
            timesResurfaced: originalQuote.timesResurfaced,
            lastResurfacedAt: originalQuote.lastResurfacedAt,
            fontStyle: fontStyle
        )

        store.update(updated)
    }

    private func toggleFavorite() {
        isFavorite.toggle()
        var updated = previewQuote
        updated.isFavorite = isFavorite
        store.update(updated)
    }

    // MARK: - Visual helpers

    // Background for text fields
    private var fieldBackground: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.06)
        } else {
            return Color.white.opacity(0.6)
        }
    }

    // Same vibe as the bottom filter chip (for Close/Edit)
    private var filterChipGradient: LinearGradient {
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
            colors: colors.map { $0.opacity(colorScheme == .dark ? 0.65 : 1.0) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Pink gradient for the Share button (matches + button)
    /// Pastel pink border for "Share It"
    private var shareBorderGradient: LinearGradient {
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
            colors: colors.map { $0.opacity(colorScheme == .dark ? 0.80 : 1.0) },
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // Same palette as the cards
    private func gradientColors(for style: PastelStyle) -> [Color] {
        switch style {
        case .mint:
            return [Color.mint.opacity(0.7), .white]
        case .blush:
            return [Color.pink.opacity(0.7), .white]
        case .lilac:
            return [Color.purple.opacity(0.6), .white]
        case .sky:
            return [Color.blue.opacity(0.5), .white]
        case .peach:
            return [Color.orange.opacity(0.6), .white]
        case .butter:
            return [Color.yellow.opacity(0.6), .white]
        }
    }
}

// MARK: - UIKit share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: Context) { }
}

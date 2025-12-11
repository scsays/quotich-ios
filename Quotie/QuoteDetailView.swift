import SwiftUI

struct QuoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var store: QuoteStore

    let quote: Quote
    @State private var showingEdit = false

    private var currentQuote: Quote {
        store.quotes.first(where: { $0.id == quote.id }) ?? quote
    }

    private var shareText: String {
        var lines: [String] = ["“\(currentQuote.text)”"]
        if !currentQuote.author.isEmpty { lines.append("— \(currentQuote.author)") }
        if !currentQuote.source.isEmpty { lines.append("Source: \(currentQuote.source)") }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 10)

                bigQuoteCard

                actionRow

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 18)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditQuoteSheet(quote: currentQuote)
                .environmentObject(store)
        }
    }

    private var bigQuoteCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("“\(currentQuote.text)”")
                .font(.system(.title2, design: fontDesign(for: currentQuote.fontStyle)).weight(.semibold))
                .foregroundStyle(DesignSystem.primaryText(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if !currentQuote.author.isEmpty || !currentQuote.source.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if !currentQuote.author.isEmpty {
                        Text("— \(currentQuote.author)")
                            .font(.headline)
                            .foregroundStyle(DesignSystem.secondaryText(scheme))
                    }
                    if !currentQuote.source.isEmpty {
                        Text(currentQuote.source)
                            .font(.subheadline)
                            .foregroundStyle(DesignSystem.secondaryText(scheme).opacity(0.9))
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DesignSystem.cardGradient(for: currentQuote.colorStyle, scheme: scheme))
                .shadow(color: DesignSystem.cardShadow, radius: 22, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(scheme == .dark ? 0.12 : 0.18), lineWidth: 0.8)
        )
    }

    private var actionRow: some View {
        HStack {
            ShareLink(item: shareText) {
                RoundActionButton(systemName: "square.and.arrow.up", size: 46, filled: false)
            }

            Spacer()

            Button {
                store.toggleFavorite(currentQuote)
            } label: {
                RoundActionButton(
                    systemName: currentQuote.isFavorite ? "heart.fill" : "heart",
                    size: 58,
                    filled: true
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showingEdit = true
            } label: {
                RoundActionButton(systemName: "pencil", size: 46, filled: false)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
    }

    private func fontDesign(for style: FontStyle) -> Font.Design {
        switch style {
        case .standard: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        }
    }
}

private struct RoundActionButton: View {
    @Environment(\.colorScheme) private var scheme

    let systemName: String
    let size: CGFloat
    let filled: Bool

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: filled ? 20 : 18, weight: .heavy))
            .foregroundStyle(filled ? .white : DesignSystem.primaryText(scheme))
            .frame(width: size, height: size)
            .background(
                Circle().fill(backgroundFill)
            )
            .overlay(
                Circle().stroke(Color.white.opacity(scheme == .dark ? 0.12 : 0.22), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.35 : 0.12), radius: 14, y: 8)
            .contentShape(Circle())
    }

    // Avoids the “Color vs Material” ternary type mismatch by returning AnyShapeStyle
    private var backgroundFill: AnyShapeStyle {
        if filled {
            return AnyShapeStyle(DesignSystem.monsterPurple)
        } else {
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }
}

private struct EditQuoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: QuoteStore
    
    @Environment(\.colorScheme) private var scheme
    @State private var colorStyle: PastelStyle = .mint
    
    let quote: Quote
    
    @State private var text: String = ""
    @State private var author: String = ""
    @State private var source: String = ""
    
    var body: some View {
        NavigationView {
            let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper
            ZStack {
                bg.ignoresSafeArea()
                Form {
                    Section("Quote") {
                        TextEditor(text: $text)
                            .frame(minHeight: 120)
                    }
                    Section("Details") {
                        TextField("Author", text: $author)
                        TextField("Source", text: $source)
                    }
                    Section("Card Color") {
                        colorPickerGrid
                    }
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("Edit Quote")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            let updated = Quote(
                                id: quote.id,
                                text: text,
                                author: author,
                                source: source,
                                isFavorite: quote.isFavorite,
                                colorStyle: colorStyle,
                                timesResurfaced: quote.timesResurfaced,
                                lastResurfacedAt: quote.lastResurfacedAt,
                                fontStyle: quote.fontStyle
                            )

                            store.update(updated)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
                .tint(DesignSystem.monsterPurple)
                .onAppear {
                    text = quote.text
                    author = quote.author
                    source = quote.source
                    colorStyle = quote.colorStyle
                }
                
            }
            
        }
        
    }
    private var colorPickerGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5),
            spacing: 10
        ) {
            ForEach(PastelStyle.allCases, id: \.self) { style in
                colorSwatch(style)
            }
        }
        .padding(.vertical, 6)
    }
    @ViewBuilder
    private func colorSwatch(_ style: PastelStyle) -> some View {
        let isSelected = (style == colorStyle)

        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(DesignSystem.cardGradient(for: style, scheme: scheme))
            .frame(height: 34)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? DesignSystem.monsterPurple : Color.white.opacity(0.18),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .onTapGesture { colorStyle = style }
    }
}


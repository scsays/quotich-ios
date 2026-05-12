import SwiftUI

struct QuoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var store: QuoteStore

    let quote: Quote
    @State private var showingEdit = false

    // Memmi
    @State private var memmiMessage: String?
    @State private var isLoadingMemmi = false
    @State private var showMemmiEntrance = false

    // Community Post State
    @State private var showPostToCommunity = false
    @State private var isPostingToCommunity = false
    @State private var didPostToCommunity = false
    @State private var postError: String? = nil
    @State private var showPostErrorAlert = false
    @State private var postSuccessMessage: String? = nil
    @State private var showPostSuccessAlert = false

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
                bigQuoteCard
                memmiSection

                Spacer(minLength: 24)

                actionRow
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 26)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                .tint(DesignSystem.monsterPurple)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditQuoteSheet(quote: currentQuote)
                .environmentObject(store)
        }
        .sheet(isPresented: $showPostToCommunity) {
            PostToCommunitySheet(
                quote: currentQuote,
                scheme: scheme,
                isPosting: $isPostingToCommunity,
                onSubmit: { author, source in
                    Task { await postCurrentQuoteToCommunity(author: author, source: source) }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert("Posted to Community", isPresented: $showPostSuccessAlert) {
            Button("Nice", role: .cancel) {}
        } message: {
            Text(postSuccessMessage ?? "Your quote was posted successfully.")
        }
        .alert("Couldn’t post to Community", isPresented: $showPostErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(postError ?? "Unknown error.")
        }
        .onAppear {
            Task { await loadMemmi() }
        }
    }

    // MARK: - Quote Card

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

    // MARK: - Memmi Section

    private var memmiSection: some View {
        VStack(spacing: 12) {
            if isLoadingMemmi {
                MemmiBubble(text: "Memmi is chewing on this one…")
                    .opacity(0.7)
            } else if let memmiMessage {
                MemmiBubble(text: memmiMessage)
                    .scaleEffect(showMemmiEntrance ? 1.05 : 1.0)
                    .shadow(
                        color: showMemmiEntrance ? DesignSystem.monsterPurple.opacity(0.4) : .clear,
                        radius: 18
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showMemmiEntrance)
            }

            dateConsumedBadge
        }
    }

    private var dateConsumedBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 13, weight: .bold))

            Text("Date consumed")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .textCase(.uppercase)
                .kerning(0.7)

            Circle()
                .fill(DesignSystem.monsterPurple.opacity(0.45))
                .frame(width: 4, height: 4)

            Text(consumedDateText)
                .font(.system(.caption, design: fontDesign(for: currentQuote.fontStyle), weight: .semibold))
        }
        .foregroundStyle(DesignSystem.monsterPurple)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.18 : 0.11))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.28 : 0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var consumedDateText: String {
        guard currentQuote.createdAt != .distantPast else { return "Unknown" }

        return currentQuote.createdAt.formatted(
            .dateTime
                .weekday(.wide)
                .month(.abbreviated)
                .day()
                .year()
        )
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack {
            ShareLink(item: shareText) {
                RoundActionButton(systemName: "square.and.arrow.up", size: 58, filled: false)
            }

            Spacer()

            Button { showPostToCommunity = true } label: {
                RoundActionButton(
                    systemName: didPostToCommunity ? "checkmark.circle.fill" : "person.3.fill",
                    size: 58,
                    filled: false
                )
                .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .disabled(isPostingToCommunity)
            .opacity(isPostingToCommunity ? 0.6 : 1.0)

            Spacer()

            Button { store.toggleFavorite(currentQuote) } label: {
                FavoriteActionButton(isFavorite: currentQuote.isFavorite, size: 58)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { showingEdit = true } label: {
                RoundActionButton(systemName: "pencil", size: 58, filled: false)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
    }

    // MARK: - Post to Community

    private func postCurrentQuoteToCommunity(author: String?, source: String?) async {
        await MainActor.run {
            isPostingToCommunity = true
            postError = nil
        }

        do {
            let submittedAuthor = author
            let submittedSource = source

            try await CommunityFeedService.shared.submitQuote(
                text: currentQuote.text,
                author: submittedAuthor,
                source: submittedSource
            )

            let verified = (try? await CommunityFeedService.shared.verifyQuotePosted(
                text: currentQuote.text,
                author: submittedAuthor,
                source: submittedSource
            )) ?? false

            // ✅ Refresh SnackBarView feed even if not currently on Community
            NotificationCenter.default.post(name: .communityFeedDidChange, object: nil)

            await MainActor.run {
                isPostingToCommunity = false
                showPostToCommunity = false
                didPostToCommunity = true
                postSuccessMessage = verified
                    ? "Verified — this quote is now visible in the Community feed."
                    : "The post request succeeded. It may take a moment to appear in Community."
                showPostSuccessAlert = true
            }

            Task {
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                await MainActor.run { didPostToCommunity = false }
            }

        } catch {
            await MainActor.run {
                isPostingToCommunity = false
                postError = error.localizedDescription
                showPostErrorAlert = true
            }
        }
    }

    // MARK: - Memmi

    private func loadMemmi() async {
        if let cached = currentQuote.memmiReaction {
            memmiMessage = cached
            return
        }

        await MainActor.run { isLoadingMemmi = true }

        do {
            let response = try await MemmiService.shared.enrichQuote(currentQuote.text)

            await MainActor.run {
                memmiMessage = response.memmi
                isLoadingMemmi = false
                showMemmiEntrance = true
            }

            store.updateMemmiReaction(for: currentQuote.id, reaction: response.memmi)

            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run { showMemmiEntrance = false }
            }

        } catch {
            await MainActor.run {
                memmiMessage = "Memmi lost the thought. Try again?"
                isLoadingMemmi = false
            }
        }
    }

    private func fontDesign(for style: FontStyle) -> Font.Design {
        switch style {
        case .standard: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        }
    }
}

// MARK: - Supporting Views (paste-safe)

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
            .background(Circle().fill(backgroundFill))
            .overlay(
                Circle().stroke(Color.white.opacity(scheme == .dark ? 0.12 : 0.22), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.35 : 0.12), radius: 14, y: 8)
    }

    private var backgroundFill: AnyShapeStyle {
        filled ? AnyShapeStyle(DesignSystem.monsterPurple) : AnyShapeStyle(.ultraThinMaterial)
    }
}

private struct FavoriteActionButton: View {
    @Environment(\.colorScheme) private var scheme

    let isFavorite: Bool
    let size: CGFloat

    var body: some View {
        Image(systemName: isFavorite ? "heart.fill" : "heart")
            .font(.system(size: 20, weight: .heavy))
            .foregroundStyle(isFavorite ? DesignSystem.monsterPurple : DesignSystem.primaryText(scheme))
            .frame(width: size, height: size)
            .background(Circle().fill(.ultraThinMaterial))
            .overlay(
                Circle().stroke(Color.white.opacity(scheme == .dark ? 0.12 : 0.22), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.35 : 0.12), radius: 14, y: 8)
    }
}

private struct PostToCommunitySheet: View {
    let quote: Quote
    let scheme: ColorScheme
    @Binding var isPosting: Bool
    let onSubmit: (_ author: String?, _ source: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var author: String = ""
    @State private var source: String = ""

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        NavigationView {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        introCard
                        quotePreviewCard
                        detailFields
                        postButton

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Post to Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .fontWeight(.semibold)
                        .disabled(isPosting)
                }
            }
            .tint(DesignSystem.monsterPurple)
            .onAppear {
                author = quote.author
                source = quote.source
            }
        }
    }

    private var introCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(DesignSystem.monsterPurple)
                .frame(width: 42, height: 42)
                .background(Circle().fill(DesignSystem.monsterPurple.opacity(0.18)))

            VStack(alignment: .leading, spacing: 3) {
                Text("Share this with the Community")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DesignSystem.primaryText(scheme))
                Text("Review the card and details before posting.")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.secondaryText(scheme))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: 22, scheme: scheme)
    }

    private var quotePreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("“\(quote.text)”")
                .font(.system(.title2, design: fontDesign(for: quote.fontStyle)).weight(.semibold))
                .foregroundStyle(DesignSystem.primaryText(scheme))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                if !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("— \(author.trimmingCharacters(in: .whitespacesAndNewlines))")
                        .font(.headline)
                        .foregroundStyle(DesignSystem.secondaryText(scheme))
                }

                if !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(source.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.secondaryText(scheme).opacity(0.9))
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DesignSystem.cardGradient(for: quote.colorStyle, scheme: scheme))
                .shadow(color: DesignSystem.cardShadow, radius: 22, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(scheme == .dark ? 0.12 : 0.18), lineWidth: 0.8)
        )
    }

    private var detailFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Community Details")
                .font(.headline.weight(.bold))
                .foregroundStyle(DesignSystem.primaryText(scheme))

            VStack(spacing: 12) {
                communityTextField(title: "Author", placeholder: "Who said it?", text: $author)
                communityTextField(title: "Source", placeholder: "Book, speech, song, etc.", text: $source)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, scheme: scheme)
    }

    private func communityTextField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            TextField(placeholder, text: text)
                .font(.body.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(scheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.68))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06), lineWidth: 1)
                )
        }
    }

    private var postButton: some View {
        Button {
            let a = author.trimmingCharacters(in: .whitespacesAndNewlines)
            let s = source.trimmingCharacters(in: .whitespacesAndNewlines)
            onSubmit(a.isEmpty ? nil : a, s.isEmpty ? nil : s)
        } label: {
            HStack(spacing: 10) {
                Spacer()
                if isPosting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 17, weight: .bold))
                }
                Text(isPosting ? "Posting and verifying…" : "Post to Community")
                    .font(.headline.weight(.bold))
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .fill(DesignSystem.monsterPurple)
                    .shadow(color: DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.38 : 0.22), radius: 16, y: 8)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPosting)
        .opacity(isPosting ? 0.75 : 1.0)
    }

    private func fontDesign(for style: FontStyle) -> Font.Design {
        switch style {
        case .standard: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        }
    }
}

// ✅ This is what your compiler was missing.
private struct EditQuoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: QuoteStore
    @Environment(\.colorScheme) private var scheme

    let quote: Quote

    @State private var text: String = ""
    @State private var author: String = ""
    @State private var source: String = ""
    @State private var colorStyle: PastelStyle = .mint

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

                    Section {
                        Button {
                            store.delete(quote)
                            dismiss()
                        } label: {
                            Text("Delete Quote")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                    .listRowBackground(
                        Capsule().fill(scheme == .dark ? Color.red.opacity(0.75) : Color.red.opacity(0.85))
                    )
                    .listRowSeparator(.hidden)
                }
                .navigationTitle("Edit Quote")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                            .fontWeight(.semibold)
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
                                fontStyle: quote.fontStyle,
                                memmiReaction: quote.memmiReaction,
                                createdAt: quote.createdAt
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
                .padding(.top, 24)
            }
        }
    }

    private var colorPickerGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5),
            spacing: 10
        ) {
            ForEach(PastelStyle.allCases, id: \.self) { style in
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignSystem.cardGradient(for: style, scheme: scheme))
                    .frame(height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                style == colorStyle ? DesignSystem.monsterPurple : Color.white.opacity(0.18),
                                lineWidth: style == colorStyle ? 2 : 1
                            )
                    )
                    .onTapGesture { colorStyle = style }
            }
        }
        .padding(.vertical, 6)
    }
}

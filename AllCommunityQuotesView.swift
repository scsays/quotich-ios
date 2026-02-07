import SwiftUI

struct AllCommunityQuotesView: View {
    @EnvironmentObject private var store: QuoteStore
    @Environment(\.dismiss) private var dismiss

    let scheme: ColorScheme

    enum Filter: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case mostFavorited = "Most Favorited"
        case surprise = "Surprise Me"

        var id: String { rawValue }
    }

    @State private var filter: Filter = .newest

    @State private var quotes: [CommunityFeedQuote] = []
    @State private var isLoading = false
    @State private var error: String? = nil

    @State private var offset: Int = 0
    private let pageSize: Int = 30

    @State private var selectedQuote: CommunityFeedQuote? = nil

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        ZStack {
            bg.ignoresSafeArea()
                .navigationBarBackButtonHidden(true)
            VStack(spacing: 12) {
                header

                filterRow

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error {
                    Spacer()
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") { load(reset: true) }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignSystem.monsterPurple)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(quotes) { quote in
                                QuoteCardView(
                                    quote: quote.asLocalQuote(),
                                    onToggleFavorite: { /* hook later */ }
                                )
                                .onTapGesture { selectedQuote = quote }
                            }

                            if filter != .surprise {
                                Button {
                                    load(reset: false)
                                } label: {
                                    Text("Load More")
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
                        .padding(16)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") { dismiss() }
            }
            ToolbarItem(placement: .principal) {
                Text("All Community Quotes").font(.headline)
            }
        }
        .sheet(item: $selectedQuote) { quote in
            CommunityQuoteDetailSheet(
                quote: quote,
                scheme: scheme,
                isLiked: false,
                isAdded: false,
                onToggleLike: { },
                onAdd: { addToMyQuotes(quote) }
            )
            .presentationDetents([.medium, .large])
        }
        .onAppear { load(reset: true) }
        .onChange(of: filter) { _ in load(reset: true) }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Browse the full community library")
                .font(.title3.weight(.bold))
            Text("Filter by time, favorites, or let fate pick one.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
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
                                Capsule().fill(filter == f ? DesignSystem.monsterPurple : Color.white.opacity(scheme == .dark ? 0.08 : 0.65))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
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
                    case .newest: return .new
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
                    quotes.append(contentsOf: rows)
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

    private func addToMyQuotes(_ quote: CommunityFeedQuote) {
        store.addQuote(
            text: quote.text,
            author: quote.author ?? "",
            source: quote.source ?? "",
            colorStyle: .mint,
            fontStyle: .rounded
        )
    }
}

import SwiftUI

enum AppTab: String {
    case home, account
    // Snack Bar is presented modally (fullScreenCover)
}

struct RootTabView: View {
    @StateObject private var store = QuoteStore()
    @ObservedObject private var notifications = MemmiNotifications.shared

    @State private var selectedTab: AppTab = .home
    @State private var showingAddQuote = false
    @State private var showingSearch = false
    @State private var showingSnackBar = false

    @State private var isScrolling: Bool = false
    @State private var favoritesOnly: Bool = false

    // Deep-link: set when user taps a resurface notification
    @State private var resurfacedQuote: Quote?

    var body: some View {
        ZStack {
            Group {
                switch selectedTab {
                case .home:
                    HomeFeedView(
                        favoritesOnly: favoritesOnly,
                        isSearchActive: showingSearch,
                        isScrolling: $isScrolling
                    )
                    .environmentObject(store)

                case .account:
                    SettingsView(store: store, onBack: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            selectedTab = .home
                        }
                    })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Bottom bar ONLY on Home and ONLY when SnackBar is not showing
        .safeAreaInset(edge: .bottom) {
            if selectedTab == .home && !showingSnackBar {
                ZStack {
                    BottomTabBar(
                        selectedTab: $selectedTab,
                        favoritesOnly: $favoritesOnly,
                        onSnackTapped: { showingSnackBar = true },
                        onSearchTapped: { showingSearch = true },
                        onAddTapped: { showingAddQuote = true },
                        showsAddButton: false
                    )
                    .opacity(isScrolling ? 0 : 1)
                    .offset(y: isScrolling ? 20 : 0)
                    .animation(.easeOut(duration: 0.25), value: isScrolling)

                    // Persistent PLUS button (never fades)
                    Button(action: { showingAddQuote = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .heavy))
                            .frame(width: 62, height: 62)
                            .background(
                                Circle()
                                    .fill(DesignSystem.monsterPurple)
                                    .shadow(color: Color.black.opacity(0.22), radius: 14, y: 8)
                            )
                            .foregroundStyle(.white)
                    }
                    .offset(y: -14)
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            store.applyDailyHungerDecay()
            store.updateWidgetQuoteOfTheDay()

            // Request notification permission and schedule both channels
            MemmiNotifications.shared.requestAuthorizationIfNeeded { granted in
                guard granted else { return }
                MemmiNotifications.shared.refreshHungryNudge(hungerLevel: store.hungerLevel)
                store.scheduleResurfaceNotificationIfNeeded()
            }
        }
        // Observe deep-link: when user taps a resurface notification, show the quote
        .onChange(of: notifications.pendingResurfaceQuoteID) { quoteID in
            guard let id = quoteID else { return }
            resurfacedQuote = store.quotes.first(where: { $0.id == id })
            notifications.pendingResurfaceQuoteID = nil
        }
        .sheet(isPresented: $showingAddQuote) {
            AddQuoteView(store: store)
        }
        .sheet(isPresented: $showingSearch) {
            SearchView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showingSnackBar) {
            SnackBarView(onBack: { showingSnackBar = false })
                .environmentObject(store)
        }
        // Resurface sheet — opens automatically when notification is tapped
        .sheet(item: $resurfacedQuote) { quote in
            NavigationStack {
                QuoteDetailView(quote: quote)
                    .environmentObject(store)
            }
        }
    }
}

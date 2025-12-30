import SwiftUI

enum AppTab: String {
    case home, account
    // Snack Bar is presented modally (fullScreenCover)
}

struct RootTabView: View {
    @StateObject private var store = QuoteStore()

    @State private var selectedTab: AppTab = .home
    @State private var showingAddQuote = false
    @State private var showingSearch = false
    @State private var showingSnackBar = false

    @State private var isScrolling: Bool = false
    @State private var favoritesOnly: Bool = false

    var body: some View {
        ZStack {
            Group {
                switch selectedTab {
                case .home:
                    HomeFeedView(
                        favoritesOnly: favoritesOnly,
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
        // ✅ Bottom bar ONLY on Home and ONLY when SnackBar is not showing
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
        // ✅ These modifiers must be attached to a real view (not inside safeAreaInset)
        .onAppear {
            store.applyDailyHungerDecay()
            store.updateWidgetQuoteOfTheDay()
            MemmiNotifications.shared.refreshHungryNudge(hungerLevel: store.hungerLevel)
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
    }
}

import SwiftUI

enum AppTab: String {
    case home, snack, account
}

struct RootTabView: View {
    @StateObject private var store = QuoteStore()

    @State private var selectedTab: AppTab = .home
    @State private var showingAddQuote = false
    @State private var showingSearch = false
    
    @State private var isScrolling: Bool = false

    // Favorites filter toggle (lives at root so bar + feed share it)
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

                case .snack:
                    SnackBarView()
                        .environmentObject(store)

                case .account:
                    AccountView()
                        .environmentObject(store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ZStack {
                // Fading bar WITHOUT the plus button
                BottomTabBar(
                    selectedTab: $selectedTab,
                    favoritesOnly: $favoritesOnly,
                    onSearchTapped: { showingSearch = true },
                    onAddTapped: { showingAddQuote = true },
                    showsAddButton: false
                )
                .opacity(isScrolling ? 0 : 1)
                .offset(y: isScrolling ? 20 : 0)
                .animation(Animation.easeOut(duration: 0.25), value: isScrolling)

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
                .offset(y: -14)  // float it a bit
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            store.applyDailyHungerDecay()
            store.updateWidgetQuoteOfTheDay()
        }
        .sheet(isPresented: $showingAddQuote) {
            AddQuoteView(store: store)
        }
        .sheet(isPresented: $showingSearch) {
            SearchView()
                .environmentObject(store)
        }
    }
}

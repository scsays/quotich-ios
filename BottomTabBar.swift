import SwiftUI

struct BottomTabBar: View {
    @Environment(\.colorScheme) private var scheme

    @Binding var selectedTab: AppTab
    @Binding var favoritesOnly: Bool

    var onSearchTapped: () -> Void
    var onAddTapped: () -> Void
    var showsAddButton: Bool = true

    var body: some View {
        HStack(spacing: 18) {

            // Search (opens SearchView as a sheet)
            Button {
                onSearchTapped()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Search")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(DesignSystem.monsterPurple)
            }

            // Favorites (toggles filter on Home)
            Button {
                favoritesOnly.toggle()
                selectedTab = .home
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: favoritesOnly ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Favorites")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(favoritesOnly ? DesignSystem.monsterPurple : .secondary)
            }

            
            // Add Quote (big +)
            if showsAddButton {
                Button(action: onAddTapped) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .heavy))
                        .frame(width: 54, height: 54)
                        .background(
                            Circle()
                                .fill(DesignSystem.monsterPurple)
                                .shadow(color: Color.black.opacity(0.22), radius: 14, y: 8)
                        )
                        .foregroundStyle(.white)
                }
            } else {
                // keep spacing so layout stays even
                Spacer()
                    .frame(width: 54, height: 54)
            }

            // Snack Bar (tab destination)
            tabButton(tab: .snack, system: "tray", title: "Snack Bar")

            // Account (tab destination)
            tabButton(tab: .account, system: "person.crop.circle", title: "Account")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DesignSystem.glassMaterial(for: scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(scheme == .dark ? 0.12 : 0.22), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(scheme == .dark ? 0.35 : 0.12), radius: 18, y: 8)
        )
    }

    private func tabButton(tab: AppTab, system: String, title: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                // IMPORTANT: uses the passed-in `system` value
                Image(systemName: system)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selectedTab == tab ? DesignSystem.monsterPurple : .secondary)
        }
    }
}

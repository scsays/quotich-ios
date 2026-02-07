import SwiftUI

struct BottomTabBar: View {
    @Environment(\.colorScheme) private var scheme

    @Binding var selectedTab: AppTab
    @Binding var favoritesOnly: Bool

    var onSnackTapped: () -> Void
    var onSearchTapped: () -> Void
    var onAddTapped: () -> Void
    var showsAddButton: Bool = true

    // MARK: - Colors

    private var inactiveColor: Color { .secondary }                // ✅ matches Account gray
    private var activeColor: Color { DesignSystem.monsterPurple }  // ✅ Memmi purple
    private var snackSymbol: String {
        // Prefer popcorn if available; fall back gracefully on older iOS.
        if UIImage(systemName: "popcorn") != nil { return "popcorn" }
        if UIImage(systemName: "popcorn.fill") != nil { return "popcorn.fill" }
        return "takeoutbag.and.cup.and.straw"
    }

    var body: some View {
        HStack(spacing: 18) {

            // Search (sheet)
            Button {
                onSearchTapped()
            } label: {
                tabLabel(system: "magnifyingglass", title: "Search")
                    .foregroundStyle(inactiveColor) // ✅ now gray
            }

            // Favorites (toggles filter on Home)
            Button {
                favoritesOnly.toggle()
                selectedTab = .home
            } label: {
                tabLabel(system: favoritesOnly ? "heart.fill" : "heart", title: "Favorites")
                    .foregroundStyle(favoritesOnly ? activeColor : inactiveColor) // ✅ purple only when active
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
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: 54, height: 54)
            }
            // Snack Bar (sheet/modal)
            Button {
                onSnackTapped()
            } label: {
                tabLabel(system: snackSymbol, title: "Snack Bar")
                    .foregroundStyle(inactiveColor) // ✅ keep gray
            }

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

    // MARK: - Shared label

    private func tabLabel(system: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: system)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Account tab button

    private func tabButton(tab: AppTab, system: String, title: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            tabLabel(system: system, title: title)
                .foregroundStyle(selectedTab == tab ? activeColor : inactiveColor)
        }
    }
}

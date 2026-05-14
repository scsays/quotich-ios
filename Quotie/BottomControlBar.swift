import SwiftUI

struct BottomControlBar: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var searchText: String
    @Binding var showFavoritesOnly: Bool

    var onSearchTapped: () -> Void
    var onAddQuote: () -> Void
    var onSnackBar: () -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        HStack(spacing: 14) {

            // Favorites toggle
            floatingPill {
                showFavoritesOnly.toggle()
            } label: {
                Image(systemName: showFavoritesOnly ? "star.fill" : "line.3.horizontal")
            }

            // Search field
            searchField
                .onTapGesture {
                    onSearchTapped()
                }

            // Snack Bar button
            floatingPill {
                onSnackBar()
            } label: {
                Image(systemName: "sparkles")
            }

            // Add quote
            floatingPill {
                onAddQuote()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search quotes", text: $searchText)
                .focused($searchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 16, scheme: colorScheme)
    }

    private func floatingPill(
        action: @escaping () -> Void,
        label: @escaping () -> some View
    ) -> some View {
        Button(action: action) {
            label()
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .liquidGlass(cornerRadius: 16, scheme: colorScheme)
        }
    }
}


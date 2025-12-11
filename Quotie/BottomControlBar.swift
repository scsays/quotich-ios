import SwiftUI

struct BottomControlBar: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var searchText: String
    @Binding var showFavoritesOnly: Bool
    var onSearchTapped: () -> Void
    var onAddQuote: () -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        HStack(spacing: 14) {

            // MARK: - Favorites Toggle
            floatingPill {
                showFavoritesOnly.toggle()
            } label: {
                Image(systemName: showFavoritesOnly ? "star.fill" : "line.3.horizontal")
            }

            // MARK: - Search Field (Liquid Glass)
            searchField

            // MARK: - Add Quote
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

    // MARK: - Search Field Wrapper
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
        .onTapGesture {
            searchFocused = true
        }
    }

    // MARK: - Floating Pill Button
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
extension View {
    func circularGlassButton(size: CGFloat = 44) -> some View {
        self
            .frame(width: size, height: size)
            .background(
                Circle().fill(.ultraThinMaterial)
            )
            .overlay(
                Circle().stroke(Color.white.opacity(0.25), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }
}



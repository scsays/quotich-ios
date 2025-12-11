import SwiftUI

extension View {
    func cardElevation(
        highlighted: Bool,
        scheme: ColorScheme
    ) -> some View {
        self.shadow(
            color: scheme == .dark
                ? Color.white.opacity(highlighted ? 0.28 : 0.12)
                : Color.black.opacity(0.12),
            radius: highlighted ? 32 : 16,
            y: highlighted ? 10 : 6
        )
    }
}


import SwiftUI

// MARK: - Design System
// This file centralizes ALL visual language:
// glass, glow, elevation, color, and text behavior.

enum DesignSystem {

    // MARK: - Core Colors

    static let monsterPurple = Color(
        red: 0.78,
        green: 0.68,
        blue: 0.92
    )

    static let lightPaper = Color(
        red: 0.97,
        green: 0.96,
        blue: 0.95
    )

    static let darkPaper = Color(
        red: 0.06,
        green: 0.06,
        blue: 0.08
    )
    
    // MARK: - Text Colors

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color.black
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.85)
            : Color.black.opacity(0.85)
    }

    // MARK: - Card Gradients

    static func cardGradient(
        for style: PastelStyle,
        scheme: ColorScheme
    ) -> LinearGradient {

        let colors: [Color]

        if scheme == .dark {
            switch style {
            case .mint:
                colors = [Color(red: 0.16, green: 0.34, blue: 0.28),
                          Color(red: 0.10, green: 0.12, blue: 0.14)]
            case .blush:
                colors = [Color(red: 0.36, green: 0.18, blue: 0.24),
                          Color(red: 0.12, green: 0.12, blue: 0.14)]
            case .lilac:
                colors = [Color(red: 0.28, green: 0.20, blue: 0.40),
                          Color(red: 0.12, green: 0.12, blue: 0.15)]
            case .sky:
                colors = [Color(red: 0.14, green: 0.24, blue: 0.40),
                          Color(red: 0.10, green: 0.12, blue: 0.16)]
            case .peach:
                colors = [Color(red: 0.40, green: 0.22, blue: 0.14),
                          Color(red: 0.12, green: 0.12, blue: 0.14)]
            case .butter:
                colors = [Color(red: 0.40, green: 0.34, blue: 0.16),
                          Color(red: 0.12, green: 0.12, blue: 0.14)]
            }
        } else {
            switch style {
            case .mint:   colors = [Color.mint.opacity(0.65), .white]
            case .blush:  colors = [Color.pink.opacity(0.65), .white]
            case .lilac:  colors = [Color.purple.opacity(0.55), .white]
            case .sky:    colors = [Color.blue.opacity(0.50), .white]
            case .peach:  colors = [Color.orange.opacity(0.55), .white]
            case .butter: colors = [Color.yellow.opacity(0.55), .white]
            }
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Elevation

    static let floatingShadow = Color.black.opacity(0.28)
    static let cardShadow = Color.black.opacity(0.18)

    // MARK: - Text Glow (Dark Mode Only)

    static func textGlow(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.45)
            : .clear
    }

    static func secondaryTextGlow(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.25)
            : .clear
    }

    // MARK: - Glass Material

    static func glassMaterial(for scheme: ColorScheme) -> Material {
        scheme == .dark ? .ultraThinMaterial : .thinMaterial
    }
}

// MARK: - Glass Modifier

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, scheme: ColorScheme) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        scheme == .dark
                        ? Color.white.opacity(0.12)
                        : Color.white.opacity(0.32)
                    )
                    .overlay(
                        // Inner highlight
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                scheme == .dark
                                ? Color.white.opacity(0.20)
                                : Color.white.opacity(0.35),
                                lineWidth: 0.8
                            )
                            .blendMode(.overlay)
                    )
            )
            .shadow(
                color: scheme == .dark
                ? Color.black.opacity(0.4)
                : Color.black.opacity(0.15),
                radius: 10,
                y: 4
            )
    }
}


// MARK: - Glow Helpers

extension View {

    /// Soft glow used for emphasis (buttons, highlights).
    func softGlow(
        color: Color,
        intensity: CGFloat = 0.55,
        radius: CGFloat = 18,
        scheme: ColorScheme
    ) -> some View {
        self.shadow(
            color: scheme == .dark
                ? color.opacity(intensity)
                : .clear,
            radius: radius
        )
    }
}





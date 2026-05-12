import SwiftUI

// MARK: - MonsterMood

enum MonsterMood: String {
    case starving, hungry, snackish, content, enlightened

    /// Derive mood from raw hunger level (0–5).
    static func from(hungerLevel: Int) -> MonsterMood {
        switch hungerLevel {
        case 0:    return .starving
        case 1:    return .hungry
        case 2:    return .snackish
        case 3:    return .content
        default:   return .enlightened   // 4 and 5
        }
    }

    /// Derive mood from normalised progress (0.0–1.0) used by the ring avatar.
    static func from(progress: Double) -> MonsterMood {
        switch progress {
        case ..<0.01: return .starving
        case ..<0.21: return .hungry
        case ..<0.41: return .snackish
        case ..<0.61: return .content
        default:      return .enlightened
        }
    }

    /// Visual progress for meters. Enlightened starts at hunger level 4,
    /// so it should read as full even before the persisted cap of 5.
    static func visualProgress(fromHungerLevel hungerLevel: Int) -> Double {
        if from(hungerLevel: hungerLevel) == .enlightened { return 1.0 }
        return min(max(Double(hungerLevel) / 5.0, 0), 1)
    }

    var assetName: String {
        switch self {
        case .starving:    return "memmi_starving"
        case .hungry:      return "memmi_hungry"
        case .snackish:    return "memmi_snackish"
        case .content:     return "memmi_content"
        case .enlightened: return "memmi_enlightened"
        }
    }

    /// A user-facing display label.
    var displayName: String { rawValue.capitalized }
}

// MARK: - Monster Mood Status Badge

struct MonsterMoodStatusBadge: View {
    let mood: MonsterMood
    let size: CGFloat
    let scheme: ColorScheme
    var fontStyle: FontStyle = .rounded

    var body: some View {
        Text(mood.displayName)
            .font(.system(size: max(10, size * 0.105), weight: .black, design: fontDesign(for: fontStyle)))
            .kerning(0.25)
            .foregroundStyle(scheme == .dark ? Color(red: 0.13, green: 0.08, blue: 0.05) : Color(red: 0.10, green: 0.06, blue: 0.04))
            .lineLimit(1)
            .minimumScaleFactor(0.68)
            .padding(.horizontal, max(10, size * 0.085))
            .padding(.vertical, max(4, size * 0.03))
            .background(
                Capsule(style: .continuous)
                    .fill(Color(red: 1.0, green: 0.91, blue: 0.74).opacity(scheme == .dark ? 0.96 : 0.98))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color(red: 0.27, green: 0.14, blue: 0.08).opacity(0.28), lineWidth: 1)
                    )
            )
            .shadow(color: Color.white.opacity(scheme == .dark ? 0.18 : 0.75), radius: 1.2, x: 0, y: 0.8)
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.20 : 0.10), radius: 2.5, x: 0, y: 1.2)
            .accessibilityHidden(true)
    }

    private func fontDesign(for style: FontStyle) -> Font.Design {
        switch style {
        case .standard: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        }
    }
}

// MARK: - QuoteMonsterView

struct QuoteMonsterView: View {
    @Environment(\.colorScheme) private var scheme

    let mood: MonsterMood
    var size: CGFloat = 64
    var badgeFontStyle: FontStyle = .rounded

    var body: some View {
        let uiImage = MemmiImageCache.image(named: mood.assetName, scheme: scheme)
                   ?? UIImage(named: "QuoteMonster")

        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .renderingMode(.original)
                    .interpolation(.high)
                    .antialiased(true)
                    .resizable()
                    .scaledToFit()
                    .overlay(alignment: .top) {
                        if size >= 96 {
                            MonsterMoodStatusBadge(mood: mood, size: size, scheme: scheme, fontStyle: badgeFontStyle)
                                .padding(.top, size * 0.035)
                        }
                    }
            } else {
                Image(systemName: "face.smiling")
                    .font(.system(size: size * 0.75, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .compositingGroup()
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 6, y: 4)
        .accessibilityLabel("Memmi – \(mood.displayName)")
    }
}

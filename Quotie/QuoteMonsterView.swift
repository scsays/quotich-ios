import SwiftUI

// MARK: - MonsterMood

enum MonsterMood: String {
    case starving, hungry, snackish, content, enlightened

    /// Derive mood from raw hunger level.
    /// The visible ladder is: Starving 1/5, Hungry 2/5,
    /// Snackish 3/5, Content 4/5, Enlightened 5/5.
    static func from(hungerLevel: Int) -> MonsterMood {
        switch hungerLevel {
        case ...1: return .starving
        case 2:    return .hungry
        case 3:    return .snackish
        case 4:    return .content
        default:   return .enlightened
        }
    }

    /// Derive mood from normalised progress (0.0–1.0) used by the ring avatar.
    static func from(progress: Double) -> MonsterMood {
        switch progress {
        case ...0.2: return .starving
        case ...0.4: return .hungry
        case ...0.6: return .snackish
        case ...0.8: return .content
        default:     return .enlightened
        }
    }

    /// Visual progress for meters: one mood per fifth of the meter.
    static func visualProgress(fromHungerLevel hungerLevel: Int) -> Double {
        switch hungerLevel {
        case ...1: return 0.2
        case 2:    return 0.4
        case 3:    return 0.6
        case 4:    return 0.8
        default:   return 1.0
        }
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
    var displayName: String {
        switch self {
        case .starving: return "Starving"
        default:        return rawValue.capitalized
        }
    }
}

// MARK: - Monster Mood Status Badge

struct MonsterMoodStatusBadge: View {
    let mood: MonsterMood
    let size: CGFloat
    let scheme: ColorScheme
    var fontStyle: FontStyle = .rounded

    var body: some View {
        Text(mood.displayName)
            .font(.system(size: max(9, size * 0.088), weight: .black, design: fontDesign(for: fontStyle)))
            .kerning(0.25)
            .foregroundStyle(scheme == .dark ? Color(red: 0.13, green: 0.08, blue: 0.05) : Color(red: 0.10, green: 0.06, blue: 0.04))
            .lineLimit(1)
            .minimumScaleFactor(0.68)
            .padding(.horizontal, max(9, size * 0.072))
            .padding(.vertical, max(3, size * 0.024))
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

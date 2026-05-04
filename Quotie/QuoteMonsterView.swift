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

// MARK: - QuoteMonsterView

struct QuoteMonsterView: View {
    @Environment(\.colorScheme) private var scheme

    let mood: MonsterMood
    var size: CGFloat = 64

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

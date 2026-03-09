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
        case 3, 4: return .content
        default:   return .enlightened   // 5 (full) or above
        }
    }

    /// Derive mood from normalised progress (0.0–1.0) used by the ring avatar.
    static func from(progress: Double) -> MonsterMood {
        switch progress {
        case ..<0.01: return .starving
        case ..<0.21: return .hungry
        case ..<0.41: return .snackish
        case ..<0.81: return .content
        default:      return .enlightened
        }
    }

    /// Asset catalog name for each mood.
    var assetName: String {
        switch self {
        case .starving:    return "memmi_starving"
        case .hungry:      return "memmi_hungry"
        case .snackish:    return "memmi_snackish"
        case .content:     return "memmi_content"
        case .enlightened: return "memmi_enlightened"
        }
    }
}

// MARK: - QuoteMonsterView

struct QuoteMonsterView: View {
    let mood: MonsterMood
    var size: CGFloat = 64

    var body: some View {
        let uiImage = UIImage(named: mood.assetName) ?? UIImage(named: "QuoteMonster")

        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    // .screen blends black pixels into the background, effectively
                    // making the solid black backdrop invisible on any background colour.
                    .blendMode(.screen)
            } else {
                Image(systemName: "face.smiling")
                    .font(.system(size: size * 0.75, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 6, y: 4)
        .accessibilityLabel("Memmi – \(mood.rawValue)")
    }
}

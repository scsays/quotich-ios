import SwiftUI

enum MonsterMood: String {
    case neutral, excited, happy
}

struct QuoteMonsterView: View {
    let mood: MonsterMood
    var size: CGFloat = 64   // <-- prevents “huge monster” surprises

    var body: some View {
        let preferred = UIImage(named: mood.assetName)
        let fallback  = UIImage(named: "QuoteMonster")

        Group {
            if let uiImage = preferred ?? fallback {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "face.smiling")
                    .font(.system(size: size * 0.75, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 6, y: 4)
        .accessibilityLabel("Quote Monster")
    }
}

private extension MonsterMood {
    var assetName: String {
        // When you add mood assets later, swap these names.
        // For now: always use your real asset.
        "QuoteMonster"
    }
}

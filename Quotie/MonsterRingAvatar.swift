import SwiftUI

struct MonsterRingAvatar: View {
    @Environment(\.colorScheme) private var scheme

    let progress: Double          // 0.0 ... 1.0
    let collapseT: CGFloat        // 0 = expanded, 1 = collapsed
    let onTap: () -> Void

    // Derived sizes
    private var size: CGFloat { lerp(92, 66, collapseT) }          // collapsed is bigger now
    private var ringLine: CGFloat { lerp(8, 6, collapseT) }
    private var innerPadding: CGFloat { lerp(14, 10, collapseT) }

    // Ring fades out as we collapse
    private var ringOpacity: Double { Double(1 - collapseT) }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Ring background (fades out)
                ringBackground
                    .opacity(ringOpacity)

                // Ring progress (fades out)
                ringProgress
                    .opacity(ringOpacity)

                Image("QuoteMonster")
                    .resizable()
                    .scaledToFit()
                    .padding(innerPadding)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: collapseT)
    }

    // MARK: - Ring Layers (glow only on the ring stroke)
    private var ringBackground: some View {
        Circle()
            .trim(from: 0.12, to: 0.88) // ~3/4 ring
            .stroke(
                Color.white.opacity(scheme == .dark ? 0.20 : 0.32),
                style: StrokeStyle(lineWidth: ringLine, lineCap: .round)
            )
            // glow on ring ONLY (not on monster)
            .shadow(color: DesignSystem.monsterPurple.opacity(0.35), radius: 10, x: 0, y: 0)
            .shadow(color: DesignSystem.monsterPurple.opacity(0.20), radius: 18, x: 0, y: 0)
            .rotationEffect(.degrees(90))
    }

    private var ringProgress: some View {
        let clamped = min(max(progress, 0), 1)
        let start: CGFloat = 0.12
        let end: CGFloat = start + CGFloat(clamped) * (0.88 - 0.12)

        return Circle()
            .trim(from: start, to: end)
            .stroke(
                DesignSystem.monsterPurple,
                style: StrokeStyle(lineWidth: ringLine, lineCap: .round)
            )
            .rotationEffect(.degrees(90))
            // slightly stronger glow in dark mode
            .shadow(
                color: DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.55 : 0.25),
                radius: 10, x: 0, y: 0
            )
    }

    // MARK: - Helpers
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * min(max(t, 0), 1)
    }
}

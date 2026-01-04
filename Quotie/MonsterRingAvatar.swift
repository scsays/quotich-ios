import SwiftUI

struct MonsterRingAvatar: View {
    @Environment(\.colorScheme) private var scheme
    @State private var glowPulse = false

    let progress: Double          // 0.0 ... 1.0
    let collapseT: CGFloat        // 0 = expanded, 1 = collapsed
    let onTap: () -> Void

    // MARK: - Bigger sizing (this is the main change)
    // Feel free to tweak these 3 numbers if you want even larger/smaller.
    private var size: CGFloat { lerp(132, 92, collapseT) }      // was 92,66
    private var ringLine: CGFloat { lerp(10, 8, collapseT) }    // was 8,6
    private var memmiSize: CGFloat { lerp(78, 58, collapseT) }  // was 56,44

    private var ringOpacity: Double { Double(1 - collapseT) }

    // Consider “full” with float tolerance
    private var isFull: Bool { progress >= 0.999 }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                ringBackground.opacity(ringOpacity)
                ringProgress.opacity(ringOpacity)

                if isFull {
                    glowHalo
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                memmiImage
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: collapseT)
        .onAppear { glowPulse = isFull }
        .onChange(of: isFull) { _, newValue in
            glowPulse = newValue
        }
    }

    // MARK: - Memmi
    private var memmiImage: some View {
        Group {
            if UIImage(named: "QuoteMonster") != nil {
                Image("QuoteMonster")
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "face.smiling.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(memmiSize * 0.18)
                    .foregroundStyle(DesignSystem.monsterPurple.opacity(0.85))
                    .background(
                        Circle().fill(.ultraThinMaterial)
                    )
            }
        }
        .frame(width: memmiSize, height: memmiSize)
        // ⛔️ Removed clipShape(Circle()) because it can make the avatar *feel* smaller/cropped.
        .shadow(
            color: Color.black.opacity(scheme == .dark ? 0.25 : 0.10),
            radius: 10, x: 0, y: 6
        )
        .shadow(
            color: isFull ? DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.22 : 0.14) : .clear,
            radius: 18, x: 0, y: 0
        )
    }

    // MARK: - Glow Halo
    private var glowHalo: some View {
        Circle()
            .fill(DesignSystem.monsterPurple.opacity(glowPulse ? glowOpacityHigh : glowOpacityLow))
            .frame(width: memmiSize + glowExtraSize, height: memmiSize + glowExtraSize)
            .blur(radius: glowPulse ? glowBlurHigh : glowBlurLow)
            .scaleEffect(glowPulse ? 1.12 : 1.00)
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowPulse)
    }

    // MARK: - Ring Layers
    private var ringBackground: some View {
        Circle()
            .trim(from: 0.12, to: 0.88)
            .stroke(
                Color.white.opacity(scheme == .dark ? 0.20 : 0.32),
                style: StrokeStyle(lineWidth: ringLine, lineCap: .round)
            )
            .rotationEffect(.degrees(90))
            .shadow(color: DesignSystem.monsterPurple.opacity(0.10), radius: 14, x: 0, y: 0)
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
            .shadow(
                color: DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.55 : 0.25),
                radius: 10, x: 0, y: 0
            )
    }

    // MARK: - Glow tuning (≈15% brighter)
    private var glowOpacityLow: Double { scheme == .dark ? 0.21 : 0.14 }
    private var glowOpacityHigh: Double { scheme == .dark ? 0.33 : 0.21 }

    private var glowBlurLow: CGFloat { scheme == .dark ? 21 : 18 }
    private var glowBlurHigh: CGFloat { scheme == .dark ? 28 : 25 }

    private var glowExtraSize: CGFloat { lerp(32, 24, collapseT) } // slightly larger halo to match bigger avatar

    // MARK: - Helpers
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * min(max(t, 0), 1)
    }
}

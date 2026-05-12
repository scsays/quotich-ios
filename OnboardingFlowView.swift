import SwiftUI

struct OnboardingFlowView: View {
    var onFinish: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var step: Int = 0

    private let steps: [OnboardingStep] = OnboardingStep.allCases

    var body: some View {
        let currentStep = steps[step]
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        ZStack {
            bg.ignoresSafeArea()

            LinearGradient(
                colors: [
                    DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.38 : 0.26),
                    bg.opacity(0.96),
                    DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.18 : 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 18)

                TabView(selection: $step) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, onboardingStep in
                        OnboardingFeatureCard(step: onboardingStep)
                            .padding(.horizontal, 22)
                            .padding(.top, 18)
                            .padding(.bottom, 16)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer(for: currentStep)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
            }
        }
        .font(DesignSystem.appFont(.body))
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let uiImage = MemmiImageCache.image(named: "memmi_content", scheme: scheme) ?? UIImage(named: "QuoteMonster") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)
                    .shadow(color: .black.opacity(0.14), radius: 7, y: 4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Meet Memmi")
                    .font(DesignSystem.appFont(.title3, weight: .black))
                Text("Your living quote collection")
                    .font(DesignSystem.appFont(.caption, weight: .semibold))
                    .foregroundStyle(DesignSystem.secondaryText(scheme))
            }

            Spacer()

            Button("Skip") { onFinish() }
                .font(DesignSystem.appFont(.subheadline, weight: .bold))
                .foregroundStyle(DesignSystem.monsterPurple)
        }
    }

    private func footer(for currentStep: OnboardingStep) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 7) {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == step ? DesignSystem.monsterPurple : DesignSystem.secondaryText(scheme).opacity(0.18))
                        .frame(width: index == step ? 24 : 7, height: 7)
                        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: step)
                }
            }

            HStack(spacing: 12) {
                if step > 0 {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { step -= 1 }
                    } label: {
                        Text("Back")
                            .font(DesignSystem.appFont(.headline, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(DesignSystem.primaryText(scheme))
                    .background(
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(scheme == .dark ? 0.12 : 0.34), lineWidth: 1))
                    )
                }

                Button {
                    if step < steps.count - 1 {
                        withAnimation(.easeOut(duration: 0.2)) { step += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(step < steps.count - 1 ? currentStep.ctaTitle : "Start collecting")
                        .font(DesignSystem.appFont(.headline, weight: .black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(
                    Capsule(style: .continuous)
                        .fill(DesignSystem.monsterPurple)
                        .shadow(color: DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.36 : 0.24), radius: 14, y: 7)
                )
            }
        }
    }
}

private enum OnboardingStep: Int, CaseIterable, Identifiable {
    case feedMemmi
    case saveFavorites
    case snackBar
    case community
    case comfortReminders

    var id: Int { rawValue }

    var eyebrow: String {
        switch self {
        case .feedMemmi: return "Hunger Meter"
        case .saveFavorites: return "Your Feed"
        case .snackBar: return "Snack Bar"
        case .community: return "Community Feed"
        case .comfortReminders: return "Make it yours"
        }
    }

    var title: String {
        switch self {
        case .feedMemmi: return "Feed Memmi with the words you keep"
        case .saveFavorites: return "Save, favorite, and revisit your quotes"
        case .snackBar: return "Grab quick quotes from the Snack Bar"
        case .community: return "Find quotes from the community"
        case .comfortReminders: return "Keep Memmi cozy in your rhythm"
        }
    }

    var subtitle: String {
        switch self {
        case .feedMemmi:
            return "Every quote you add fills the Hunger Meter and helps Memmi grow from Starving to Enlightened."
        case .saveFavorites:
            return "Your newest quotes live in Grid View. Tap the heart to build a favorites view for the lines you need most."
        case .snackBar:
            return "Need inspiration fast? Snack Bar gives you ready-to-add quotes that can feed Memmi in a tap."
        case .community:
            return "Browse community quotes, preview what resonates, then add the best ones straight into your feed."
        case .comfortReminders:
            return "Choose light or dark mode, then let Memmi resurface favorite quotes throughout the day."
        }
    }

    var ctaTitle: String {
        switch self {
        case .feedMemmi: return "Show me the feed"
        case .saveFavorites: return "Next: Snack Bar"
        case .snackBar: return "Next: Community"
        case .community: return "Next: comfort"
        case .comfortReminders: return "Start collecting"
        }
    }
}

private struct OnboardingFeatureCard: View {
    @Environment(\.colorScheme) private var scheme
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 18) {
            preview
                .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                Text(step.eyebrow.uppercased())
                    .font(DesignSystem.appFont(.caption, weight: .black))
                    .kerning(1.3)
                    .foregroundStyle(DesignSystem.monsterPurple)

                Text(step.title)
                    .font(DesignSystem.appFont(.title2, weight: .black))
                    .foregroundStyle(DesignSystem.primaryText(scheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.subtitle)
                    .font(DesignSystem.appFont(.callout, weight: .semibold))
                    .foregroundStyle(DesignSystem.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(scheme == .dark ? 0.14 : 0.34), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(scheme == .dark ? 0.32 : 0.12), radius: 24, y: 12)
        )
    }

    @ViewBuilder
    private var preview: some View {
        switch step {
        case .feedMemmi:
            HungerPreview()
        case .saveFavorites:
            FeedAndFavoritePreview()
        case .snackBar:
            SnackBarPreview()
        case .community:
            CommunityPreview()
        case .comfortReminders:
            ComfortRemindersPreview()
        }
    }
}

private struct HungerPreview: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(scheme == .dark ? DesignSystem.darkPaper.opacity(0.84) : Color.white.opacity(0.76))
                    .frame(height: 210)

                VStack(spacing: 10) {
                    MonsterRingAvatar(progress: 0.8, collapseT: 0, badgeFontStyle: .rounded, onTap: {})
                        .frame(height: 152)

                    HungerMeterBar(progress: 0.8, label: "Content")
                        .padding(.horizontal, 22)
                }
                .padding(.top, 12)
            }

            FeaturePill(systemImage: "plus.circle.fill", text: "Add quotes to fill the meter")
        }
    }
}

private struct FeedAndFavoritePreview: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                MiniQuoteCard(text: "Stay soft. Stay awake.", source: "Grid View", isFavorite: true, colorStyle: .lilac)
                MiniQuoteCard(text: "Small rituals become a life.", source: "Newest first", isFavorite: false, colorStyle: .mint)
            }

            HStack(spacing: 9) {
                FeaturePill(systemImage: "square.grid.2x2", text: "Grid")
                FeaturePill(systemImage: "heart.fill", text: "Favorites")
                FeaturePill(systemImage: "rectangle.portrait", text: "Card")
            }
        }
    }
}

private struct SnackBarPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            PreviewHeader(title: "Snack Bar", systemImage: "popcorn.fill")

            VStack(spacing: 10) {
                SnackRow(title: "Recommended Quotes", subtitle: "Quick adds for hungry Memmi", icon: "sparkles")
                SnackRow(title: "Add to My Quotes", subtitle: "One tap sends it to your feed", icon: "plus.circle.fill")
            }
        }
    }
}

private struct CommunityPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            PreviewHeader(title: "Community Feed", systemImage: "person.3.fill")

            MiniQuoteCard(text: "What is broken is also where the light gets in.", source: "Community quote", isFavorite: true, colorStyle: .peach)
                .frame(maxWidth: 260)

            FeaturePill(systemImage: "plus", text: "Add to My Quotes")
        }
    }
}

private struct ComfortRemindersPreview: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AppearanceTile(title: "Light", systemImage: "sun.max.fill", isSelected: scheme != .dark)
                AppearanceTile(title: "Dark", systemImage: "moon.fill", isSelected: scheme == .dark)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 9) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(DesignSystem.monsterPurple)
                    Text("Favorite resurface")
                        .font(DesignSystem.appFont(.headline, weight: .black))
                    Spacer()
                    Text("9:00 AM")
                        .font(DesignSystem.appFont(.caption, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                Text("“Here’s one worth carrying today.”")
                    .font(DesignSystem.quoteFont(.rounded, textStyle: .callout, weight: .semibold))
                    .foregroundStyle(DesignSystem.secondaryText(scheme))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.thinMaterial))
        }
    }
}

private struct HungerMeterBar: View {
    let progress: Double
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Hunger Meter")
                    .font(DesignSystem.appFont(.caption, weight: .black))
                Spacer()
                Text(label)
                    .font(DesignSystem.appFont(.caption, weight: .black))
                    .foregroundStyle(DesignSystem.monsterPurple)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.20))
                    Capsule()
                        .fill(DesignSystem.monsterPurple)
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 12)
        }
    }
}

private struct MiniQuoteCard: View {
    @Environment(\.colorScheme) private var scheme
    let text: String
    let source: String
    let isFavorite: Bool
    let colorStyle: PastelStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("“\(text)”")
                .font(DesignSystem.quoteFont(.rounded, textStyle: .callout, weight: .semibold))
                .foregroundStyle(DesignSystem.primaryText(scheme))
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text(source)
                    .font(DesignSystem.appFont(.caption2, weight: .bold))
                    .foregroundStyle(DesignSystem.secondaryText(scheme))
                Spacer()
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(DesignSystem.appFont(size: 14, weight: .heavy))
                    .foregroundStyle(isFavorite ? DesignSystem.monsterPurple : .secondary)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DesignSystem.cardGradient(for: colorStyle, scheme: scheme))
                .shadow(color: DesignSystem.cardShadow.opacity(0.8), radius: 8, y: 4)
        )
    }
}

private struct FeaturePill: View {
    @Environment(\.colorScheme) private var scheme
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(DesignSystem.appFont(.caption, weight: .black))
            .foregroundStyle(DesignSystem.primaryText(scheme))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(.thinMaterial))
    }
}

private struct PreviewHeader: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(DesignSystem.appFont(size: 18, weight: .black))
                .foregroundStyle(DesignSystem.monsterPurple)
                .frame(width: 34, height: 34)
                .background(Circle().fill(DesignSystem.monsterPurple.opacity(0.16)))

            Text(title)
                .font(DesignSystem.appFont(.headline, weight: .black))
                .foregroundStyle(DesignSystem.primaryText(scheme))

            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.thinMaterial))
    }
}

private struct SnackRow: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(DesignSystem.appFont(size: 17, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(DesignSystem.monsterPurple))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.appFont(.subheadline, weight: .black))
                Text(subtitle)
                    .font(DesignSystem.appFont(.caption, weight: .semibold))
                    .foregroundStyle(DesignSystem.secondaryText(scheme))
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.thinMaterial))
    }
}

private struct AppearanceTile: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(DesignSystem.appFont(size: 20, weight: .black))
            Text(title)
                .font(DesignSystem.appFont(.caption, weight: .black))
        }
        .foregroundStyle(isSelected ? .white : DesignSystem.primaryText(scheme))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? DesignSystem.monsterPurple : Color.white.opacity(scheme == .dark ? 0.08 : 0.52))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(isSelected ? 0.22 : 0.14), lineWidth: 1)
                )
        )
    }
}

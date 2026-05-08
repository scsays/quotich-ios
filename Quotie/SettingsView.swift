import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @ObservedObject var store: QuoteStore

    var onBack: () -> Void = {}

    @AppStorage(
        "widgetDailyQuotesEnabled",
        store: UserDefaults(suiteName: "group.Quotie-Team.Quotie")
    ) private var widgetDailyQuotesEnabled: Bool = true

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        topBackRow
                            .padding(.top, 10)

                        sectionCard(title: "About Memmi") {
                            Text("Memmi is your little quote vault — a place to capture the lines you fall in love with and resurface them later when you need them most.")
                                .foregroundStyle(DesignSystem.primaryText(scheme))
                        }

                        sectionCard(title: "How it works") {
                            settingsRow("Capture quotes you love as colorful cards.", systemImage: "square.fill.text.grid.1x2")
                            settingsRow("Star your favorites to see them more often.", systemImage: "heart.fill")
                            settingsRow("Resurface quotes when you need them.", systemImage: "sparkles")
                        }

                        sectionCard(title: "Widgets") {
                            Toggle(isOn: $widgetDailyQuotesEnabled) {
                                Text("Show a daily quote in widgets")
                                    .font(.system(.body, design: .rounded))
                            }
                            .toggleStyle(.switch)

                            Text("When enabled, the widget will show a quote from your collection each day.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }

                        sectionCard(title: "Credits") {
                            Text("Created by Andre Bradford (S.C. Says)")
                                .foregroundStyle(DesignSystem.primaryText(scheme))

                            if let version = appVersion {
                                Text("Version \(version)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        sectionCard(title: "Debug") {
                            Button("Re-run Onboarding") {
                                UserDefaults.standard.set(false, forKey: OnboardingKeys.hasSeenOnboarding)
                            }
                            .buttonStyle(.bordered)

#if DEBUG
                            Button(action: fireTestResurfaceNotification) {
                                Label("Test Resurface Notification (5s)", systemImage: "bell.badge")
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignSystem.monsterPurple)
#endif
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Helpers

    private var topBackRow: some View {
        HStack {
            Button {
                onBack()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))

                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(scheme == .dark ? .white : .black)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(scheme == .dark ? Color.black.opacity(0.86) : Color.white.opacity(0.96))
                        .overlay(
                            Capsule()
                                .stroke(
                                    scheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.10),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(
                    color: Color.black.opacity(scheme == .dark ? 0.30 : 0.12),
                    radius: 12,
                    x: 0,
                    y: 5
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.headline)
                .foregroundStyle(DesignSystem.primaryText(scheme))

            Spacer()

            Color.clear
                .frame(width: 72, height: 1)
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(DesignSystem.primaryText(scheme))

            content()
                .font(.body)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, scheme: scheme)
    }

    private func settingsRow(_ text: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DesignSystem.monsterPurple)
                .frame(width: 22)

            Text(text)
                .foregroundStyle(DesignSystem.primaryText(scheme))

            Spacer(minLength: 0)
        }
        .font(.subheadline)
    }

#if DEBUG
    private func fireTestResurfaceNotification() {
        MemmiNotifications.shared.requestAuthorizationIfNeeded { granted in
            guard granted else { return }
            guard let quote = store.quotes.randomElement() else { return }
            MemmiNotifications.shared.debugFireResurfaceNotification(
                quoteID: quote.id,
                text: quote.text,
                author: quote.author,
                inSeconds: 5
            )
        }
    }
#endif

    private var appVersion: String? {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""

        let versionText = version.isEmpty ? nil : version
        let buildText = build.isEmpty ? nil : "build \(build)"

        return [versionText, buildText].compactMap { $0 }.joined(separator: " ")
    }
}

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
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .buttonStyle(.bordered)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Works even if sheet dismissal is acting weird
                        onBack()
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

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

    private var appVersion: String? {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""

        let versionText = version.isEmpty ? nil : version
        let buildText = build.isEmpty ? nil : "build \(build)"

        return [versionText, buildText].compactMap { $0 }.joined(separator: " ")
    }
}

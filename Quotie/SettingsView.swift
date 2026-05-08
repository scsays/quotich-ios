import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @ObservedObject var store: QuoteStore

    var onBack: () -> Void = {}

    @AppStorage(
        "widgetDailyQuotesEnabled",
        store: UserDefaults(suiteName: "group.Quotie-Team.Quotie")
    ) private var widgetDailyQuotesEnabled: Bool = true

    @AppStorage(MemmiNotifications.notificationsEnabledKey) private var notificationsEnabled: Bool = true
    @AppStorage(MemmiNotifications.favoriteResurfaceFrequencyKey) private var resurfaceFrequency: Int = 1

    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

    private let frequencyOptions = [1, 2, 3]

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        topBackRow
                            .padding(.top, 10)

                        heroCard

                        notificationCard

                        sectionCard(title: "Widgets", systemImage: "rectangle.on.rectangle") {
                            Toggle(isOn: $widgetDailyQuotesEnabled) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Daily quote widget")
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                    Text("Show one quote from your vault on the Home Screen.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .toggleStyle(.switch)
                            .tint(DesignSystem.monsterPurple)
                        }

                        sectionCard(title: "About Memmi", systemImage: "sparkles") {
                            settingsRow("Capture quotes you love as colorful cards.", systemImage: "square.fill.text.grid.1x2")
                            settingsRow("Star favorites so Memmi knows what matters most.", systemImage: "heart.fill")
                            settingsRow("Let Memmi resurface lines when you need them.", systemImage: "bell.badge.fill")
                        }

                        sectionCard(title: "Credits", systemImage: "person.crop.circle") {
                            Text("Created by Andre Bradford (S.C. Says)")
                                .foregroundStyle(DesignSystem.primaryText(scheme))

                            if let version = appVersion {
                                Text("Version \(version)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        debugCard

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear(perform: refreshNotificationStatus)
            .onChange(of: notificationsEnabled) { enabled in
                handleNotificationsToggle(enabled)
            }
            .onChange(of: resurfaceFrequency) { _ in
                rescheduleNotificationsIfEnabled()
            }
        }
    }

    // MARK: - Sections

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.26 : 0.22))
                        .frame(width: 58, height: 58)

                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(DesignSystem.monsterPurple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(DesignSystem.primaryText(scheme))

                    Text("Tune how Memmi shows up for you.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                miniStat(value: String(store.devoursAllTimeCount()), label: "quotes")
                miniStat(value: String(store.favoriteQuotesCount()), label: "favorites")
                miniStat(value: "\(resurfaceFrequency)x", label: "daily")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroBackground)
        .overlay(heroStroke)
        .shadow(color: Color.black.opacity(scheme == .dark ? 0.32 : 0.12), radius: 18, x: 0, y: 10)
    }

    private var notificationCard: some View {
        sectionCard(title: "Notifications", systemImage: "bell.fill") {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $notificationsEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Memmi reminders")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                        Text(notificationPermissionText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(DesignSystem.monsterPurple)

                Divider().opacity(0.35)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Favorite quote resurfacing")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(DesignSystem.primaryText(scheme))

                    Picker("Times per day", selection: $resurfaceFrequency) {
                        ForEach(frequencyOptions, id: \.self) { count in
                            Text("\(count)x/day").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!notificationsEnabled)
                    .opacity(notificationsEnabled ? 1 : 0.45)

                    Text(scheduleDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var debugCard: some View {
        sectionCard(title: "Debug", systemImage: "ladybug.fill") {
            VStack(alignment: .leading, spacing: 10) {
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
        }
    }

    // MARK: - Helpers

    private var topBackRow: some View {
        HStack {
            Button {
                onBack()
                dismiss()
            } label: {
                Text("Back")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(scheme == .dark ? .white : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(backButtonBackground)
                    .shadow(
                        color: Color.black.opacity(scheme == .dark ? 0.30 : 0.12),
                        radius: 12,
                        x: 0,
                        y: 5
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private func sectionCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DesignSystem.monsterPurple)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.18 : 0.14)))

                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(DesignSystem.primaryText(scheme))
            }

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

    private func miniStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(DesignSystem.primaryText(scheme))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.45))
        )
    }

    private var heroBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        DesignSystem.monsterPurple.opacity(scheme == .dark ? 0.24 : 0.26),
                        scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.62)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var heroStroke: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(scheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.70), lineWidth: 1)
    }

    private var backButtonBackground: some View {
        Capsule()
            .fill(scheme == .dark ? Color.black.opacity(0.86) : Color.white.opacity(0.96))
            .overlay(
                Capsule()
                    .stroke(
                        scheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.10),
                        lineWidth: 1
                    )
            )
    }

    private var notificationPermissionText: String {
        switch notificationPermissionStatus {
        case .authorized, .provisional, .ephemeral:
            return notificationsEnabled ? "Hungry nudges and favorite resurfacing are on." : "Paused. Memmi will stay quiet."
        case .denied:
            return "Permission is off in iOS Settings. Turn it back on there to receive reminders."
        case .notDetermined:
            return "Turn on reminders to let iOS ask for permission."
        @unknown default:
            return "Notification status unavailable."
        }
    }

    private var scheduleDescription: String {
        guard notificationsEnabled else { return "Turn notifications on to schedule favorite quote reminders." }

        switch resurfaceFrequency {
        case 1:
            return "Memmi will surface one favorite quote each morning."
        case 2:
            return "Memmi will surface favorites in the morning and evening."
        default:
            return "Memmi will surface favorites morning, afternoon, and evening."
        }
    }

    private func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }

    private func handleNotificationsToggle(_ enabled: Bool) {
        if enabled {
            MemmiNotifications.shared.requestAuthorizationIfNeeded { granted in
                DispatchQueue.main.async {
                    refreshNotificationStatus()
                }
                guard granted else { return }
                MemmiNotifications.shared.refreshHungryNudge(hungerLevel: store.hungerLevel)
                store.scheduleResurfaceNotificationIfNeeded()
            }
        } else {
            MemmiNotifications.shared.cancelAllManagedNotifications()
            refreshNotificationStatus()
        }
    }

    private func rescheduleNotificationsIfEnabled() {
        guard notificationsEnabled else { return }
        UserDefaults.standard.removeObject(forKey: "memmi.lastResurfaceScheduledDate")
        store.scheduleResurfaceNotificationIfNeeded()
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

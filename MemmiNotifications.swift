import Foundation
import Combine
import UserNotifications

// MARK: - Memmi Notifications
// Handles two notification channels:
//   1. Hungry Nudge  — fires at 6 PM when hunger ≤ 3, rotating "feed me" messages
//   2. Smart Resurface — fires at 9 AM the next morning with a real quote from the vault

final class MemmiNotifications: NSObject, ObservableObject {
    static let shared = MemmiNotifications()
    private override init() { super.init() }

    // MARK: - Notification IDs
    private let hungryNudgeID   = "memmi.hungry.nudge"
    private let resurfaceDaily   = "memmi.resurface.daily"

    // MARK: - UserDefaults Keys
    private let lastHungryNudgeDateKey      = "memmi.lastNudgeDate"
    private let lastHungryNudgeIndexKey     = "memmi.lastNudgeMessageIndex"
    private let lastResurfaceScheduledKey   = "memmi.lastResurfaceScheduledDate"
    private let resurfaceTitleIndexKey      = "memmi.resurfaceTitleIndex"

    // MARK: - Deep Link — published so RootTabView can observe
    @Published var pendingResurfaceQuoteID: UUID?

    // MARK: - Hungry Nudge Copy
    private let hungryMessages: [String] = [
        "Getting hungry... read anything good lately?",
        "Feeling snackish... hear anything good lately?",
        "I could eat... see anything good lately?",
        "My quote tank's looking low... got any good lines for me?",
        "Little hungry over here… find anything worth saving today?"
    ]

    // MARK: - Resurface Title Copy
    private let resurfaceTitles: [String] = [
        "Memmi dug this up for you…",
        "Found this hiding in your vault ✨",
        "This one's worth revisiting…",
        "A line you once loved",
        "Memmi remembered something ✨"
    ]

    // MARK: - Authorization

    func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion?(true)
            case .denied:
                completion?(false)
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                ) { granted, _ in
                    completion?(granted)
                }
            @unknown default:
                completion?(false)
            }
        }
    }

    // MARK: - Hungry Nudge

    /// Call this whenever hunger changes or on app launch.
    func refreshHungryNudge(hungerLevel: Int) {
        guard hungerLevel <= 3 else {
            cancelNotification(id: hungryNudgeID)
            return
        }

        requestAuthorizationIfNeeded { granted in
            guard granted, !self.didScheduleHungryNudgeToday() else { return }
            self.scheduleHungryNudgeAtEvening()
        }
    }

    private func scheduleHungryNudgeAtEvening() {
        let content = UNMutableNotificationContent()
        content.title = "Memmi"
        content.body  = nextHungryMessage()
        content.sound = .default

        let fireDate = nextFiringDate(hour: 18, minute: 0)
        let trigger  = calendarTrigger(for: fireDate)
        let req      = UNNotificationRequest(identifier: hungryNudgeID, content: content, trigger: trigger)

        cancelNotification(id: hungryNudgeID)
        UNUserNotificationCenter.current().add(req)
        UserDefaults.standard.set(Date(), forKey: lastHungryNudgeDateKey)
    }

    private func didScheduleHungryNudgeToday() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: lastHungryNudgeDateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private func nextHungryMessage() -> String {
        let defaults   = UserDefaults.standard
        let lastIndex  = defaults.integer(forKey: lastHungryNudgeIndexKey)
        let nextIndex  = (lastIndex + 1) % hungryMessages.count
        defaults.set(nextIndex, forKey: lastHungryNudgeIndexKey)
        return hungryMessages[nextIndex]
    }

    // MARK: - Smart Resurface

    /// Schedule tomorrow's 9 AM resurface notification with a specific quote.
    /// Called by QuoteStore after it picks the smartest candidate.
    /// Silently skips if already scheduled today.
    func scheduleResurfaceNotification(quoteID: UUID, text: String, author: String) {
        guard !didScheduleResurfaceToday() else { return }

        requestAuthorizationIfNeeded { granted in
            guard granted else { return }

            let content       = UNMutableNotificationContent()
            content.title     = self.nextResurfaceTitle()
            let snippet       = text.count > 120 ? String(text.prefix(117)) + "…" : text
            content.body      = author.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? "“\(snippet)”"
                                    : "“\(snippet)” — \(author)"
            content.sound     = .default
            content.userInfo  = ["quoteID": quoteID.uuidString, "type": "resurface"]

            // Fire at 9 AM tomorrow
            let fireDate = self.nextFiringDate(hour: 9, minute: 0, alwaysTomorrow: true)
            let trigger  = self.calendarTrigger(for: fireDate)
            let req      = UNNotificationRequest(
                identifier: self.resurfaceDaily,
                content: content,
                trigger: trigger
            )

            self.cancelNotification(id: self.resurfaceDaily)
            UNUserNotificationCenter.current().add(req) { error in
                if error == nil {
                    UserDefaults.standard.set(Date(), forKey: self.lastResurfaceScheduledKey)
                }
            }
        }
    }

    private func didScheduleResurfaceToday() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: lastResurfaceScheduledKey) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private func nextResurfaceTitle() -> String {
        let defaults  = UserDefaults.standard
        let lastIndex = defaults.integer(forKey: resurfaceTitleIndexKey)
        let nextIndex = (lastIndex + 1) % resurfaceTitles.count
        defaults.set(nextIndex, forKey: resurfaceTitleIndexKey)
        return resurfaceTitles[nextIndex]
    }

    // MARK: - UNUserNotificationCenterDelegate

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        guard
            let idString = userInfo["quoteID"] as? String,
            let uuid     = UUID(uuidString: idString),
            (userInfo["type"] as? String) == "resurface"
        else { return }

        DispatchQueue.main.async {
            self.pendingResurfaceQuoteID = uuid
        }
    }

    func willPresentNotification(_ notification: UNNotification) -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    // MARK: - Helpers

    private func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Returns the next occurrence of hour:minute, either today (if still upcoming) or tomorrow.
    /// Pass `alwaysTomorrow: true` to force tomorrow regardless.
    private func nextFiringDate(hour: Int, minute: Int, alwaysTomorrow: Bool = false) -> Date {
        var components     = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour   = hour
        components.minute = minute
        let todayFire      = Calendar.current.date(from: components) ?? Date()

        if alwaysTomorrow || Date() >= todayFire {
            return Calendar.current.date(byAdding: .day, value: 1, to: todayFire) ?? todayFire
        }
        return todayFire
    }

    private func calendarTrigger(for date: Date) -> UNCalendarNotificationTrigger {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    // MARK: - Debug Helpers

    /// Fires a test resurface notification in `seconds` seconds — useful for simulator testing.
    func debugFireResurfaceNotification(quoteID: UUID, text: String, author: String, inSeconds seconds: TimeInterval = 5) {
        let content      = UNMutableNotificationContent()
        content.title    = "Memmi remembered something ✨"
        let snippet      = text.count > 120 ? String(text.prefix(117)) + "…" : text
        content.body     = author.trimmingCharacters(in: .whitespaces).isEmpty
                               ? "“\(snippet)”"
                               : "“\(snippet)” — \(author)"
        content.sound    = .default
        content.userInfo = ["quoteID": quoteID.uuidString, "type": "resurface"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let req     = UNNotificationRequest(
            identifier: "memmi.resurface.debug.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(req)
    }

    /// Fires a test hungry nudge in `seconds` seconds.
    func debugFireHungryNudge(inSeconds seconds: TimeInterval = 5) {
        let content   = UNMutableNotificationContent()
        content.title = "Memmi"
        content.body  = hungryMessages[0]
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let req     = UNNotificationRequest(
            identifier: "memmi.hungry.debug.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(req)
    }
}

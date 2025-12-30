import Foundation
import UserNotifications

final class MemmiNotifications {
    static let shared = MemmiNotifications()
    private init() {}

    // MARK: - Config

    private let notificationId = "memmi.hungry.nudge"

    private let messages: [String] = [
        "Getting hungry... read anything good lately?",
        "Feeling snackish... hear anything good lately?",
        "I could eat... see anything good lately?",
        "My quote tank’s looking low... got any good lines for me?",
        "Little hungry over here… find anything worth saving today?"
    ]

    // MARK: - Keys

    private let lastNudgeDateKey = "memmi.lastNudgeDate"
    private let lastMessageIndexKey = "memmi.lastNudgeMessageIndex"

    // MARK: - Public API

    func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion?(true)
            case .denied:
                completion?(false)
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion?(granted)
                }
            @unknown default:
                completion?(false)
            }
        }
    }

    /// Call this whenever hunger changes OR on app launch.
    func refreshHungryNudge(hungerLevel: Int) {
        // If hunger is above threshold, remove any pending nudge.
        guard hungerLevel <= 3 else {
            cancelHungryNudge()
            return
        }

        requestAuthorizationIfNeeded { granted in
            guard granted else { return }
            guard !self.didSendNudgeToday() else { return }

            self.scheduleHungryNudgeAtEvening()
        }
    }

    func cancelHungryNudge() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }

    // Debug helper: schedule in 10 seconds
    func scheduleTestNudgeIn10Seconds() {
        requestAuthorizationIfNeeded { granted in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Memmi"
            content.body = self.nextMessage()
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let req = UNNotificationRequest(identifier: self.notificationId, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
    }

    // MARK: - Scheduling

    private func scheduleHungryNudgeAtEvening() {
        // pick message now and store index so it rotates predictably
        let body = nextMessage()

        let content = UNMutableNotificationContent()
        content.title = "Memmi"
        content.body = body
        content.sound = .default

        // evening schedule: 6 PM local
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18
        components.minute = 0

        let now = Date()
        let todaySix = Calendar.current.date(from: components) ?? now

        // If it's already past 6 PM today, schedule tomorrow at 6 PM
        let fireDate: Date = (now < todaySix)
            ? todaySix
            : Calendar.current.date(byAdding: .day, value: 1, to: todaySix) ?? todaySix

        let fireComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)

        let req = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

        // Replace any existing pending nudge with the new one
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        UNUserNotificationCenter.current().add(req)

        markNudgeSentToday()
    }

    // MARK: - Rotation + Once/Day

    private func nextMessage() -> String {
        let defaults = UserDefaults.standard
        let lastIndex = defaults.integer(forKey: lastMessageIndexKey) // default 0
        let nextIndex = (lastIndex + 1) % messages.count
        defaults.set(nextIndex, forKey: lastMessageIndexKey)
        return messages[nextIndex]
    }

    private func didSendNudgeToday() -> Bool {
        let defaults = UserDefaults.standard
        guard let lastDate = defaults.object(forKey: lastNudgeDateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    private func markNudgeSentToday() {
        UserDefaults.standard.set(Date(), forKey: lastNudgeDateKey)
    }
}
extension MemmiNotifications {
    func debugFireTestNotification(inSeconds seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "Memmi"
        content.body = "Getting hungry...read anything good lately?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "memmi.debug.test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Debug notification failed: \(error)")
            } else {
                print("Debug notification scheduled in \(seconds)s")
            }
        }
    }
}

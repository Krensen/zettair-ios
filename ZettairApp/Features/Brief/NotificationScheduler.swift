import Foundation
import UserNotifications

/// Schedules the once-per-day local notification that pings the user to open
/// their morning brief. The brief itself is fetched on app open — the
/// notification is just a doorbell, not the delivery.
///
/// We use UNCalendarNotificationTrigger with repeats: true; iOS handles
/// time-zone and DST transitions correctly. One trigger per install. The
/// identifier is stable so re-scheduling at a different time replaces the
/// previous trigger.
@MainActor
enum BriefNotifications {
    static let identifier = "io.zettair.app.brief.daily"
    static let categoryIdentifier = "io.zettair.app.brief.daily.category"

    /// Request permission and schedule the brief. Returns true on success.
    @discardableResult
    static func requestAndSchedule(at time: DateComponents) async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        guard granted else { return false }
        await schedule(at: time)
        return true
    }

    /// Schedule without prompting (assumes permission has been granted).
    static func schedule(at time: DateComponents) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Your daily brief is ready"
        content.body  = "3 things from Wikipedia, ~90 seconds."
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        // Deep link via userInfo. The app reads this on tap and routes.
        content.userInfo = ["destination": "brief"]

        var comps = DateComponents()
        comps.hour   = time.hour
        comps.minute = time.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let request = UNNotificationRequest(identifier: identifier,
                                             content: content,
                                             trigger: trigger)
        try? await center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Has the user granted permission yet? Returns nil if they haven't been
    /// asked.
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Next scheduled fire date, for display in Settings ("next: 7:00 AM
    /// tomorrow"). Returns nil if not scheduled.
    static func nextFireDate() async -> Date? {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        guard let req = requests.first(where: { $0.identifier == identifier }) else { return nil }
        guard let trig = req.trigger as? UNCalendarNotificationTrigger else { return nil }
        return trig.nextTriggerDate()
    }
}

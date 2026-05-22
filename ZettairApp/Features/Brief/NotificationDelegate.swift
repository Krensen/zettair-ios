import Foundation
import UserNotifications
import UIKit

/// Routes notification taps. The brief notification's userInfo carries
/// `destination: "brief"`; we surface that into the router which the
/// RootView observes.
@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var router: AppRouter?

    /// Foreground: show banner + sound. Without this iOS suppresses
    /// notifications that arrive while the app is in the foreground.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  willPresent notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    /// Tap handler.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  didReceive response: UNNotificationResponse,
                                  withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            if let dest = userInfo["destination"] as? String, dest == "brief" {
                router?.tab = .brief
            }
            completionHandler()
        }
    }
}

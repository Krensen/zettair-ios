import Foundation
import CoreSpotlight
import ZettairKit

/// Donates the user's search as both an NSUserActivity (Handoff / Siri
/// Suggestions surface) and an AppIntent donation (iOS 16+ Spotlight rank).
@MainActor
enum IntentDonations {
    static func donate(query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        // NSUserActivity gives us Handoff and Siri Suggestions.
        let activity = NSUserActivity(activityType: "io.zettair.app.search")
        activity.title = q
        activity.userInfo = ["q": q]
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true
        if #available(iOS 16.0, *) {
            activity.isEligibleForPrediction = true
        }
        activity.persistentIdentifier = "search:\(queryNorm(q))"
        let attrs = CSSearchableItemAttributeSet(itemContentType: "public.text")
        attrs.title = q
        attrs.contentDescription = "Search Wikipedia via Zettair"
        activity.contentAttributeSet = attrs
        activity.webpageURL = URL(string: "https://zettair.io/?q=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)")
        activity.becomeCurrent()

        // AppIntent donation (iOS 16+).
        Task {
            let intent = SearchZettairIntent(query: q)
            try? await intent.donate()
        }
    }
}

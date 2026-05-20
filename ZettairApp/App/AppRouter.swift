import Foundation
import SwiftUI

/// Single source of truth for the active tab and search query, so deep links,
/// share extension hand-offs, AppIntents, and Spotlight all funnel here.
@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable { case search, saved, settings }

    @Published var tab: Tab = .search
    @Published var pendingQuery: String? = nil
    /// Increments each time the user re-taps the Search tab while already on
    /// it. Search tab observes this and resets to home — the universal iOS
    /// "tab re-tap returns to root" idiom.
    @Published var searchHomeRequest: Int = 0

    /// Handle inbound `zettair://search?q=...` or `https://zettair.io/?q=...`.
    func handle(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        if let q = comps.queryItems?.first(where: { $0.name == "q" })?.value, !q.isEmpty {
            tab = .search
            pendingQuery = q
            return
        }
        // Path-based form: /search?q=...
        if comps.path.contains("search"),
           let q = comps.queryItems?.first(where: { $0.name == "q" })?.value,
           !q.isEmpty {
            tab = .search
            pendingQuery = q
        }
    }

    /// Handle Siri / AppIntents / Spotlight user activities. The activity carries
    /// the query string in userInfo["q"] by convention.
    func handle(activity: NSUserActivity) {
        if let q = activity.userInfo?["q"] as? String, !q.isEmpty {
            tab = .search
            pendingQuery = q
        } else if let q = activity.title, !q.isEmpty {
            tab = .search
            pendingQuery = q
        }
    }

    func openQuery(_ q: String) {
        tab = .search
        pendingQuery = q
    }
}

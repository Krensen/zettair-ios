import Foundation
import SwiftUI
import ZettairKit

/// App-wide singletons shared via @EnvironmentObject. Keep this small — it's
/// the seam between the system (URLSession, file system) and the UI.
@MainActor
final class AppEnvironment: ObservableObject {
    let api: ZettairAPI
    let cache: any ArticleCache
    let savedStore: SavedStore                 // PRD-028 M10 placeholder
    let trendingThumbCache: TrendingThumbCache // disk-persisted (query → image URL)
    let dailyBriefStore: DailyBriefStore       // disk-persisted morning brief

    init() {
        // Bump URLCache so AsyncImage's pixel bytes survive launches. /img sets
        // Cache-Control: public, max-age=86400, so any decent disk budget is
        // enough to keep yesterday's trending thumbnails resident.
        let mem  = 20 * 1024 * 1024     // 20 MB in memory
        let disk = 200 * 1024 * 1024    // 200 MB on disk
        URLCache.shared = URLCache(memoryCapacity: mem, diskCapacity: disk)

        self.api = ZettairAPI()
        self.cache = InMemoryArticleCache(maxEntries: 100)
        self.savedStore = SavedStore()
        self.trendingThumbCache = TrendingThumbCache()
        self.dailyBriefStore = DailyBriefStore()
    }
}

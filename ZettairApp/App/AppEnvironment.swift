import Foundation
import SwiftUI
import ZettairKit

/// App-wide singletons shared via @EnvironmentObject. Keep this small — it's
/// the seam between the system (URLSession, file system) and the UI.
@MainActor
final class AppEnvironment: ObservableObject {
    let api: ZettairAPI
    let cache: any ArticleCache
    let savedStore: SavedStore   // PRD-028 M10 placeholder, in-memory only

    init() {
        self.api = ZettairAPI()
        self.cache = InMemoryArticleCache(maxEntries: 100)
        self.savedStore = SavedStore()
    }
}

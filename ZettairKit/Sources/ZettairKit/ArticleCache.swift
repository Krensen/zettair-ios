import Foundation

/// Contract for the offline article cache. Real SQLite-backed implementation
/// lands in PRD-028 M6; in-memory implementation below is enough for v0 builds
/// and tests.
public protocol ArticleCache: Sendable {
    func get(_ docno: String) async -> ArticleResponse?
    func put(_ article: ArticleResponse) async
    func clear() async
    func size() async -> Int
}

public actor InMemoryArticleCache: ArticleCache {
    public init(maxEntries: Int = 100) { self.maxEntries = maxEntries }

    private let maxEntries: Int
    private var store: [String: ArticleResponse] = [:]
    private var lru: [String] = []

    public func get(_ docno: String) -> ArticleResponse? {
        guard let v = store[docno] else { return nil }
        touch(docno)
        return v
    }

    public func put(_ article: ArticleResponse) {
        store[article.docno] = article
        touch(article.docno)
        evictIfNeeded()
    }

    public func clear() {
        store.removeAll()
        lru.removeAll()
    }

    public func size() -> Int { store.count }

    private func touch(_ docno: String) {
        if let idx = lru.firstIndex(of: docno) {
            lru.remove(at: idx)
        }
        lru.append(docno)
    }

    private func evictIfNeeded() {
        while store.count > maxEntries, let oldest = lru.first {
            store.removeValue(forKey: oldest)
            lru.removeFirst()
        }
    }
}

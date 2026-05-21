import Foundation

/// Persists the (trending query → image URL) mapping across launches so the
/// home view paints real thumbnails on first frame instead of letter-tile-then-
/// pop-in. The mapping is cheap (~6 small strings); the bytes themselves are
/// cached separately by URLCache.shared.
///
/// Entries are valid for `freshnessHours` from write time. Older entries are
/// dropped at load time so a stale thumbnail (deleted Wikipedia image, etc.)
/// gets refreshed within a day.
public actor TrendingThumbCache {
    public struct Entry: Codable, Sendable {
        public let url: String
        public let writtenAt: Date
    }

    private let url: URL
    private let freshnessHours: Double
    private var entries: [String: Entry] = [:]
    private var loaded = false

    public init(filename: String = "trending_thumbs.json", freshnessHours: Double = 24) {
        let dir = (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,
                                                appropriateFor: nil, create: true))
                  ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.url = dir.appendingPathComponent(filename)
        self.freshnessHours = freshnessHours
    }

    public func get(_ query: String) async -> URL? {
        await ensureLoaded()
        guard let e = entries[query] else { return nil }
        if Date().timeIntervalSince(e.writtenAt) > freshnessHours * 3600 {
            entries.removeValue(forKey: query)
            return nil
        }
        return URL(string: e.url)
    }

    public func put(_ query: String, _ imageURL: URL) async {
        await ensureLoaded()
        entries[query] = Entry(url: imageURL.absoluteString, writtenAt: Date())
        await persist()
    }

    public func putAll(_ pairs: [(String, URL)]) async {
        await ensureLoaded()
        let now = Date()
        for (q, u) in pairs {
            entries[q] = Entry(url: u.absoluteString, writtenAt: now)
        }
        await persist()
    }

    /// Returns the full mapping (post-freshness-filter) — for hydrating UI on
    /// first appear without doing the network calls.
    public func snapshot() async -> [String: URL] {
        await ensureLoaded()
        var out: [String: URL] = [:]
        let now = Date()
        for (k, v) in entries {
            if now.timeIntervalSince(v.writtenAt) <= freshnessHours * 3600,
               let u = URL(string: v.url) {
                out[k] = u
            }
        }
        return out
    }

    public func clear() async {
        entries = [:]
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Disk I/O

    private func ensureLoaded() async {
        guard !loaded else { return }
        loaded = true
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) else {
            return
        }
        // Drop stale entries up front so subsequent accesses are cheap.
        let cutoff = Date().addingTimeInterval(-freshnessHours * 3600)
        entries = decoded.filter { $0.value.writtenAt >= cutoff }
    }

    private func persist() async {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

import Foundation

/// One card in the morning brief. Three of these compose a day's brief.
public struct DailyBriefItem: Codable, Sendable, Equatable, Identifiable {
    public let query: String        // e.g. "openai"
    public let title: String        // e.g. "OpenAI"
    public let summaryMarkdown: String?
    public let summaryKind: String?  // "biographical" | "news"
    public let eventDate: String?
    public let imageURL: String?    // already routed through /img by the assembler
    public let articleURL: String
    public let source: String       // "google_news" | "wiki_itn" | "spike" | "popular"

    public var id: String { query }
}

public struct DailyBrief: Codable, Sendable, Equatable {
    /// Calendar date (YYYY-MM-DD) the brief is *for*, in device-local time.
    public let date: String
    public let items: [DailyBriefItem]
    public let generatedAt: Date

    public var isStale: Bool {
        // Anything more than 23h old is suspicious. We regenerate on every
        // morning open anyway, so this is belt-and-braces.
        Date().timeIntervalSince(generatedAt) > 23 * 3600
    }
}

/// Disk-persisted single-brief store, keyed by date. Re-opening the app the
/// same day reads from cache; the morning rollover wipes yesterday's entry.
public actor DailyBriefStore {
    private let fileURL: URL

    public init(filename: String = "daily_brief.json") {
        let dir = (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,
                                                appropriateFor: nil, create: true))
                  ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = dir.appendingPathComponent(filename)
    }

    public func load() async -> DailyBrief? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder.daily.decode(DailyBrief.self, from: data)
    }

    public func save(_ brief: DailyBrief) async {
        guard let data = try? JSONEncoder.daily.encode(brief) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    public func clear() async {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

private extension JSONEncoder {
    static let daily: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}
private extension JSONDecoder {
    static let daily: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

/// Today's date in device-local time, as YYYY-MM-DD. The brief is keyed by
/// this — when the date changes (midnight local), the cache miss triggers a
/// fresh fetch.
public func todayLocalDateString(now: Date = Date()) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = TimeZone.current
    return f.string(from: now)
}

/// Assembles the brief from existing endpoints. Fetches the top trending
/// items, then for each calls /search?q=... to pick up the summary, image,
/// and URL. Falls back to snippet-as-summary for items without a
/// hand-fed/news summary.
public actor DailyBriefAssembler {
    private let api: ZettairAPI
    public init(api: ZettairAPI) { self.api = api }

    /// Build a brief for the given local date, with up to `maxItems` cards.
    public func assemble(forDate date: String = todayLocalDateString(),
                          maxItems: Int = 3) async throws -> DailyBrief {
        // /api/trending order is already editorially-ranked by the server
        // (PRD-026 quality filter + PRD-021 specificity gate). We take the
        // top N and enrich each with /search for summary + image.
        let trending = try await api.trending(n: max(maxItems, 8))
        let candidates = Array(trending.items.prefix(maxItems * 2))   // headroom for fallback

        var built: [DailyBriefItem] = []
        // Sequential to keep request rate sane; could parallelise if perf bites.
        for cand in candidates {
            if built.count >= maxItems { break }
            if let item = await enrichOne(cand) {
                built.append(item)
            }
        }
        return DailyBrief(date: date, items: built, generatedAt: Date())
    }

    private func enrichOne(_ trending: TrendingItem) async -> DailyBriefItem? {
        // External (out-of-corpus) items still get a card — we just link
        // straight to Wikipedia, with no summary.
        if !trending.inIndex {
            guard let articleURL = trending.wikiURL else { return nil }
            return DailyBriefItem(
                query: trending.query,
                title: trending.title,
                summaryMarkdown: nil,
                summaryKind: nil,
                eventDate: nil,
                imageURL: nil,
                articleURL: articleURL,
                source: trending.source
            )
        }
        do {
            let r = try await api.search(trending.query, n: 1)
            guard let top = r.results.first else { return nil }
            let rawImg = top.imageURL.flatMap { ImageProxy.url(for: $0, preferredWidth: 500) }
            return DailyBriefItem(
                query: trending.query,
                title: trending.title,
                summaryMarkdown: r.summary ?? snippetAsFallback(top.snippet),
                summaryKind: r.summaryKind?.rawValue ?? "snippet",
                eventDate: r.eventDate,
                imageURL: rawImg?.absoluteString,
                articleURL: top.url,
                source: trending.source
            )
        } catch {
            return nil
        }
    }

    /// Server snippets are HTML with <b> highlights. Render-as-plain for the
    /// summary slot so callers don't have to know about it. Mostly used when
    /// the trending query has no curated summary yet.
    private func snippetAsFallback(_ html: String) -> String {
        var out = ""
        var inTag = false
        for ch in html {
            if ch == "<" { inTag = true; continue }
            if ch == ">" { inTag = false; continue }
            if !inTag { out.append(ch) }
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

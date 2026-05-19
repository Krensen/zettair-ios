import Foundation

// MARK: - Search

public struct SearchResponse: Decodable, Sendable, Equatable {
    public let query: String
    public let total: Int
    public let tookMs: Double
    public let results: [SearchResult]
    public let summary: String?
    public let summaryKind: SummaryKind?
    public let eventDate: String?
    public let related: RelatedBlock?

    enum CodingKeys: String, CodingKey {
        case query, total, results, summary, related
        case tookMs = "took_ms"
        case summaryKind = "summary_kind"
        case eventDate = "event_date"
    }

    public enum SummaryKind: String, Decodable, Sendable, Equatable {
        case biographical
        case news
    }
}

public struct SearchResult: Decodable, Sendable, Equatable, Identifiable {
    public let rank: Int
    public let score: Double
    public let docid: Int
    public let docno: String
    public let url: String
    public let snippet: String
    public let imageURL: String?
    public let readingTimeMin: Int?
    public let difficulty: String?

    public var id: String { docno }

    public var displayTitle: String {
        docno.replacingOccurrences(of: "_", with: " ")
    }

    enum CodingKeys: String, CodingKey {
        case rank, score, docid, docno, url, snippet, difficulty
        case imageURL = "image_url"
        case readingTimeMin = "reading_time_min"
    }
}

public struct RelatedBlock: Decodable, Sendable, Equatable {
    public let sourceClass: String?
    public let items: [RelatedItem]

    enum CodingKeys: String, CodingKey {
        case items
        case sourceClass = "source_class"
    }
}

public struct RelatedItem: Decodable, Sendable, Equatable, Identifiable {
    public let docno: String
    public let title: String
    public let score: Double

    public var id: String { docno }
}

// MARK: - Suggest

public struct SuggestResponse: Decodable, Sendable, Equatable {
    public let q: String
    public let suggestions: [Suggestion]
}

public struct Suggestion: Decodable, Sendable, Equatable, Identifiable {
    public let query: String
    public let count: Int

    public var id: String { query }
}

// MARK: - Trending

public struct TrendingResponse: Decodable, Sendable, Equatable {
    public let mode: String
    public let generatedAt: String?
    public let items: [TrendingItem]

    enum CodingKeys: String, CodingKey {
        case mode, items
        case generatedAt = "generated_at"
    }
}

public struct TrendingItem: Decodable, Sendable, Equatable, Identifiable {
    public let query: String
    public let title: String
    public let inIndex: Bool
    public let source: String
    public let wikiURL: String?

    public var id: String { query }

    enum CodingKeys: String, CodingKey {
        case query, title, source
        case inIndex = "in_index"
        case wikiURL = "wiki_url"
    }
}

// MARK: - Click

public struct ClickEvent: Encodable, Sendable {
    public let q: String
    public let docno: String
    public let rank: Int
    public let score: Double

    public init(q: String, docno: String, rank: Int, score: Double) {
        self.q = q
        self.docno = docno
        self.rank = rank
        self.score = score
    }
}

// MARK: - Article (PRD-028 backend addition — endpoint not yet live)

public struct ArticleResponse: Decodable, Sendable, Equatable {
    public let docno: String
    public let title: String
    public let body: String
    public let url: String
    public let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case docno, title, body, url
        case imageURL = "image_url"
    }
}

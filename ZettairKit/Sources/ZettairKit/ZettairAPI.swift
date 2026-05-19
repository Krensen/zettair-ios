import Foundation

public enum ZettairAPIError: Error, Equatable, Sendable {
    case invalidURL
    case http(status: Int)
    case decoding(String)
    case transport(String)
    case server(String)
    case emptyQuery
}

/// Lightweight async/await HTTP client against the Zettair JSON API.
///
/// The client is stateless and thread-safe; one instance can be shared by the
/// whole app. URLSession is injected so tests can stub responses.
public actor ZettairAPI {
    public static let defaultBaseURL = URL(string: "https://zettair.io")!
    public static let userAgent: String = {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        return "ZettairIOS/\(v)"
    }()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(baseURL: URL = ZettairAPI.defaultBaseURL, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let cfg = URLSessionConfiguration.default
            cfg.httpAdditionalHeaders = [
                "User-Agent": ZettairAPI.userAgent,
                "Accept": "application/json",
            ]
            cfg.timeoutIntervalForRequest = 10
            cfg.timeoutIntervalForResource = 15
            cfg.waitsForConnectivity = true
            self.session = URLSession(configuration: cfg)
        }
        self.decoder = JSONDecoder()
    }

    // MARK: Endpoints

    public func search(_ query: String, n: Int = 10) async throws -> SearchResponse {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { throw ZettairAPIError.emptyQuery }
        let url = try makeURL(path: "/search", items: [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "n", value: String(n)),
        ])
        return try await get(url)
    }

    public func suggest(_ query: String, n: Int = 8) async throws -> SuggestResponse {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            return SuggestResponse(q: "", suggestions: [])
        }
        let url = try makeURL(path: "/suggest", items: [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "n", value: String(n)),
        ])
        return try await get(url)
    }

    public func trending(n: Int = 8) async throws -> TrendingResponse {
        let url = try makeURL(path: "/api/trending", items: [
            URLQueryItem(name: "n", value: String(n)),
        ])
        return try await get(url)
    }

    /// Fire-and-forget click logging.
    public func click(_ event: ClickEvent) async {
        do {
            let url = try makeURL(path: "/click", items: [])
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(event)
            _ = try await session.data(for: req)
        } catch {
            // Click logging is best-effort; failures are intentionally swallowed.
        }
    }

    /// Returns the cleaned article body. The `/article` endpoint is a planned
    /// PRD-028 backend addition. The call surfaces a clean HTTP-404 / 501 to
    /// callers until the server lands; the offline-cache layer handles that.
    public func article(docno: String) async throws -> ArticleResponse {
        let url = try makeURL(path: "/article", items: [
            URLQueryItem(name: "docno", value: docno),
        ])
        return try await get(url)
    }

    // MARK: - Internals

    private func makeURL(path: String, items: [URLQueryItem]) throws -> URL {
        guard var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw ZettairAPIError.invalidURL
        }
        if !items.isEmpty {
            comps.queryItems = items
        }
        guard let url = comps.url else { throw ZettairAPIError.invalidURL }
        return url
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, resp) = try await transport(url)
        guard let http = resp as? HTTPURLResponse else {
            throw ZettairAPIError.transport("non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            if let msg = serverErrorMessage(from: data) {
                throw ZettairAPIError.server(msg)
            }
            throw ZettairAPIError.http(status: http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ZettairAPIError.decoding(String(describing: error))
        }
    }

    private func transport(_ url: URL) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(from: url)
        } catch {
            throw ZettairAPIError.transport(error.localizedDescription)
        }
    }

    private func serverErrorMessage(from data: Data) -> String? {
        struct E: Decodable { let error: String }
        return try? JSONDecoder().decode(E.self, from: data).error
    }
}

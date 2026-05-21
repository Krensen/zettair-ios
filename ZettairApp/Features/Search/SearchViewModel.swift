import Foundation
import SwiftUI
import SafariServices
import ZettairKit

@MainActor
final class SearchViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case results(SearchResponse)
        case error(String)
    }

    @Published var state: State = .idle
    @Published var lastQuery: String? = nil
    @Published var trending: TrendingResponse? = nil
    @Published private(set) var trendingThumbs: [String: URL] = [:]   // keyed by query
    @Published private(set) var allSuggestions: [Suggestion] = []

    var isShowingResults: Bool {
        if case .results = state { return true }
        if case .loading = state { return true }
        return false
    }

    func resetToHome() {
        state = .idle
        lastQuery = nil
        allSuggestions = []
    }

    private var suggestTask: Task<Void, Never>? = nil

    func suggestions(for draft: String) -> [Suggestion] {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return allSuggestions
    }

    func runSearch(_ query: String, api: ZettairAPI) async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        lastQuery = q
        state = .loading
        do {
            let resp = try await api.search(q, n: 10)
            state = .results(resp)
        } catch let err as ZettairAPIError {
            state = .error(humanError(err))
        } catch {
            state = .error("Unexpected error: \(error.localizedDescription)")
        }
    }

    func updateSuggestions(for draft: String, api: ZettairAPI) async {
        suggestTask?.cancel()
        let q = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 1 else {
            allSuggestions = []
            return
        }
        suggestTask = Task { [weak self] in
            // small debounce
            try? await Task.sleep(nanoseconds: 120_000_000)
            if Task.isCancelled { return }
            do {
                let resp = try await api.suggest(q, n: 8)
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.allSuggestions = resp.suggestions }
            } catch {
                // Suggestions are best-effort; swallow.
            }
        }
    }

    func loadTrending(api: ZettairAPI) async {
        do {
            let resp = try await api.trending(n: 8)
            self.trending = resp
            await fetchTrendingThumbs(for: resp, api: api)
        } catch {
            // Quietly leave nil; home view hides the rail when empty.
        }
    }

    /// /api/trending doesn't carry image URLs, so for each item we hit
    /// /search?q=<query>&n=1 in parallel and pull the top result's image_url.
    /// Results land in `trendingThumbs` keyed by item.query; rows render
    /// progressively as each fetch completes (since the dict is @Published).
    private func fetchTrendingThumbs(for trending: TrendingResponse, api: ZettairAPI) async {
        // Only fetch for items we don't already have. Trending refreshes every
        // 3h on the server; the cache survives view re-appearance but resets
        // on every successful loadTrending — fine.
        await withTaskGroup(of: (String, URL?).self) { group in
            for item in trending.items where trendingThumbs[item.query] == nil {
                group.addTask { [item] in
                    do {
                        let r = try await api.search(item.query, n: 1)
                        if let s = r.results.first?.imageURL,
                           let url = ImageProxy.url(for: s) {
                            return (item.query, url)
                        }
                    } catch {
                        // best-effort
                    }
                    return (item.query, nil)
                }
            }
            for await (q, url) in group {
                if let url { trendingThumbs[q] = url }
            }
        }
    }

    private func humanError(_ err: ZettairAPIError) -> String {
        switch err {
        case .emptyQuery: return "Type something to search."
        case .invalidURL: return "Internal: invalid URL."
        case .http(let s): return "Server returned HTTP \(s)."
        case .decoding(let m): return "Couldn't parse the response (\(m))."
        case .transport(let m): return "Network error: \(m)"
        case .server(let m): return m
        }
    }
}

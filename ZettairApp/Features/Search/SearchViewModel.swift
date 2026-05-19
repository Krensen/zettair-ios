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
    @Published private(set) var allSuggestions: [Suggestion] = []
    @Published var presentedSafariURL: URL? = nil

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
            self.trending = try await api.trending(n: 8)
        } catch {
            // Quietly leave nil; home view hides the rail when empty.
        }
    }

    func openExternalArticle(_ result: SearchResult) {
        guard let url = URL(string: result.url) else { return }
        presentedSafariURL = url
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

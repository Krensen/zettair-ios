import SwiftUI
import ZettairKit

struct SearchTabView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var viewModel = SearchViewModel()
    @State private var draft: String = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                contentLayer
            }
            .navigationTitle("Zettair")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $draft, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Wikipedia")
            .focused($searchFocused)
            .onSubmit(of: .search) { runSearch() }
            .onChange(of: draft) { newValue in
                Task { await viewModel.updateSuggestions(for: newValue, api: environment.api) }
            }
            .onChange(of: router.pendingQuery) { q in
                if let q { applyPending(q) }
            }
            .task {
                await viewModel.loadTrending(api: environment.api)
                await SpotlightIndexer.shared.ensureSeeded(api: environment.api)
            }
            .refreshable { await viewModel.loadTrending(api: environment.api) }
        }
    }

    @ViewBuilder
    private var contentLayer: some View {
        switch viewModel.state {
        case .idle:
            HomeView(
                trending: viewModel.trending,
                suggestions: viewModel.suggestions(for: draft),
                onTapTrending: { item in
                    if item.inIndex {
                        draft = item.query
                        runSearch()
                    } else if let s = item.wikiURL, let url = URL(string: s) {
                        UIApplication.shared.open(url)
                    }
                },
                onTapSuggestion: { s in
                    draft = s.query
                    runSearch()
                }
            )
        case .loading:
            ProgressView().controlSize(.large)
        case .results(let response):
            ResultsView(
                response: response,
                query: viewModel.lastQuery ?? draft,
                onTapResult: { result in
                    Task { await environment.api.click(.init(q: viewModel.lastQuery ?? draft,
                                                              docno: result.docno,
                                                              rank: result.rank,
                                                              score: result.score)) }
                },
                onTapRelated: { item in
                    draft = item.title
                    runSearch()
                }
            )
        case .error(let message):
            ErrorView(message: message) { runSearch() }
        }
    }

    private func runSearch() {
        let q = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        searchFocused = false
        environment.savedStore.pushHistory(q)
        IntentDonations.donate(query: q)
        SpotlightIndexer.shared.indexUserQuery(q)
        Task { await viewModel.runSearch(q, api: environment.api) }
    }

    private func applyPending(_ q: String) {
        draft = q
        router.pendingQuery = nil
        runSearch()
    }
}

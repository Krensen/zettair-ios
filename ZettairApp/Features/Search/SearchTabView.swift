import SwiftUI
import ZettairKit

struct SearchTabView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var viewModel = SearchViewModel()
    @State private var draft: String = ""
    @FocusState private var searchFocused: Bool
    @Namespace private var logoAnimation

    var body: some View {
        NavigationStack {
            ZStack {
                contentLayer
            }
            .toolbar { toolbar }
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $draft,
                         placement: .navigationBarDrawer(displayMode: .always),
                         prompt: "Search Wikipedia")
            .focused($searchFocused)
            .onSubmit(of: .search) { runSearch() }
            .onChange(of: draft) { newValue in
                Task { await viewModel.updateSuggestions(for: newValue, api: environment.api) }
            }
            .onChange(of: router.pendingQuery) { q in
                if let q { applyPending(q) }
            }
            .onChange(of: router.searchHomeRequest) { _ in
                if viewModel.isShowingResults || !draft.isEmpty {
                    goHome()
                }
            }
            .task {
                // Paint cached thumbnails immediately, then refresh in the
                // background. The hydrate step is cheap (disk read).
                await viewModel.hydrateTrendingThumbs(from: environment.trendingThumbCache)
                await viewModel.loadTrending(api: environment.api,
                                              thumbCache: environment.trendingThumbCache)
            }
            .refreshable {
                await viewModel.loadTrending(api: environment.api,
                                              thumbCache: environment.trendingThumbCache)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            if viewModel.isShowingResults {
                Button(action: goHome) {
                    ZettairSmallLogo(namespace: logoAnimation)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to home")
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var contentLayer: some View {
        switch viewModel.state {
        case .idle:
            if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HomeView(
                    trending: viewModel.trending,
                    trendingThumbs: viewModel.trendingThumbs,
                    onTapTrending: handleTrendingTap,
                    logoNamespace: logoAnimation
                )
                .transition(.opacity)
            } else {
                SuggestionsView(
                    suggestions: viewModel.allSuggestions,
                    onTapSuggestion: { s in
                        draft = s.query
                        runSearch()
                    }
                )
                .transition(.opacity)
            }
        case .loading:
            VStack(spacing: 12) {
                ProgressView().controlSize(.large)
                Text("Searching…").font(.footnote).foregroundStyle(.secondary)
            }
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
            .transition(.opacity)
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
        // Kick off the (~24-call) Spotlight seed sweep in the background after
        // the user's first real search — never blocks the search itself, and
        // never fires during cold launch. ensureSeeded is idempotent.
        Task.detached(priority: .background) {
            await SpotlightIndexer.shared.ensureSeeded(api: environment.api)
        }
        Task { await viewModel.runSearch(q, api: environment.api) }
    }

    private func applyPending(_ q: String) {
        draft = q
        router.pendingQuery = nil
        runSearch()
    }

    private func goHome() {
        Haptics.tap()
        searchFocused = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            draft = ""
            viewModel.resetToHome()
        }
    }

    private func handleTrendingTap(_ item: TrendingItem) {
        if item.inIndex {
            draft = item.query
            runSearch()
        } else if let s = item.wikiURL, let url = URL(string: s) {
            UIApplication.shared.open(url)
        }
    }
}

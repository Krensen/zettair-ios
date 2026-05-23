import SwiftUI
import ZettairKit

struct SearchTabView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var viewModel = SearchViewModel()
    @State private var draft: String = ""
    @Namespace private var logoAnimation

    var body: some View {
        NavigationStack {
            ActiveSearchOverlayHost(
                draft: draft,
                trending: viewModel.trending,
                trendingThumbs: viewModel.trendingThumbs,
                suggestions: viewModel.allSuggestions,
                onTapTrending: handleTrendingTap,
                onTapSuggestion: { s in
                    draft = s.query
                    runSearch()
                },
                underlying: { underlyingContent }
            )
            .toolbar { toolbar }
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $draft,
                         placement: .navigationBarDrawer(displayMode: .always),
                         prompt: "Search Wikipedia")
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

    /// What sits *behind* the active-search overlay. This is the
    /// view model's resting state — home, results, error. The overlay
    /// covers it while the search field is focused.
    @ViewBuilder
    private var underlyingContent: some View {
        switch viewModel.state {
        case .idle:
            HomeView(
                trending: viewModel.trending,
                trendingThumbs: viewModel.trendingThumbs,
                onTapTrending: handleTrendingTap,
                logoNamespace: logoAnimation
            )
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
        case .error(let message):
            ErrorView(message: message) { runSearch() }
        }
    }

    private func runSearch() {
        let q = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        environment.savedStore.pushHistory(q)
        IntentDonations.donate(query: q)
        SpotlightIndexer.shared.indexUserQuery(q)
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

/// Hosts the active-search overlay on top of the underlying content.
/// Lives here (rather than inline in the parent body) because it needs to
/// be placed *inside* `.searchable` to read `\.isSearching`. We can't read
/// the env value directly in SearchTabView's body — it would always be
/// false at that level.
private struct ActiveSearchOverlayHost<Underlying: View>: View {
    let draft: String
    let trending: TrendingResponse?
    let trendingThumbs: [String: URL]
    let suggestions: [Suggestion]
    let onTapTrending: (TrendingItem) -> Void
    let onTapSuggestion: (Suggestion) -> Void
    @ViewBuilder let underlying: () -> Underlying

    @Environment(\.isSearching) private var isSearching

    var body: some View {
        ZStack {
            underlying()
            if isSearching {
                ActiveSearchView(
                    draft: draft,
                    trending: trending,
                    trendingThumbs: trendingThumbs,
                    suggestions: suggestions,
                    onTapTrending: onTapTrending,
                    onTapSuggestion: onTapSuggestion
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearching)
    }
}

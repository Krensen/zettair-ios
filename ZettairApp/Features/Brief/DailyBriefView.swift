import SwiftUI
import ZettairKit

/// Three swipeable cards making up the morning brief. Each card is a single
/// trending item with summary, image, and quick-action buttons. Shown when
/// the user taps the morning notification or opens the Brief tab.
struct DailyBriefView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var viewModel = DailyBriefViewModel()
    @State private var page = 0

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Today's brief")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await viewModel.load(api: environment.api,
                                                          store: environment.dailyBriefStore,
                                                          force: true) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .task {
                    await viewModel.load(api: environment.api,
                                          store: environment.dailyBriefStore)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            VStack(spacing: 12) {
                ProgressView().controlSize(.large)
                Text("Assembling your brief…")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let brief):
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(brief.items.enumerated()), id: \.element.id) { idx, item in
                        BriefCardView(item: item, index: idx, total: brief.items.count)
                            .tag(idx)
                            // Card is now visibly inset from screen edges.
                            .padding(.horizontal, 28)
                            .padding(.bottom, 40)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }

        case .error(let msg):
            VStack(spacing: 12) {
                Image(systemName: "newspaper").font(.largeTitle).foregroundStyle(.secondary)
                Text(msg).foregroundStyle(.secondary)
                Button("Try again") {
                    Task { await viewModel.load(api: environment.api,
                                                  store: environment.dailyBriefStore,
                                                  force: true) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct BriefCardView: View {
    let item: DailyBriefItem
    let index: Int
    let total: Int

    @EnvironmentObject var router: AppRouter
    @State private var showingSafari: URL? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                header
                if let s = item.summaryMarkdown, !s.isEmpty {
                    Text(renderedSummary(s) ?? AttributedString(s))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                actionButtons
                Text("Source: \(prettySource)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .sheet(item: Binding<IdentifiableURL?>(
            get: { showingSafari.map(IdentifiableURL.init) },
            set: { showingSafari = $0?.url }
        )) { wrapped in
            SafariView(url: wrapped.url)
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let s = item.imageURL, let url = URL(string: s) {
            // The brief hero is intrinsically wide (~card-width × 200pt). Use a
            // representative size; SmartImageView's crop is aspect-aware so any
            // width that matches the displayed aspect works.
            SmartImageView(
                url: url,
                size: CGSize(width: 400, height: 200),
                cornerRadius: 12,
                fillParent: true,
                failureView: { BrandLetterBanner(title: item.title) }
            )
            .frame(height: 200)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("\(index + 1) of \(total)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.18), in: Capsule())
                    .foregroundStyle(.secondary)
                if item.summaryKind == "news" {
                    Label("News", systemImage: "newspaper")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.orange.opacity(0.18), in: Capsule())
                        .foregroundStyle(.orange)
                }
                if let d = item.eventDate {
                    Label(d, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(item.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                Haptics.tap()
                router.openQuery(item.query)
            } label: {
                Label("Search", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                Haptics.tap()
                if let url = URL(string: item.articleURL) {
                    showingSafari = url
                }
            } label: {
                Label("Read", systemImage: "book")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var prettySource: String {
        switch item.source {
        case "google_news": return "Google News"
        case "wiki_itn":    return "Wikipedia: In The News"
        case "spike":       return "Wikipedia pageview spike"
        case "popular":     return "Wikipedia popularity"
        default:            return item.source
        }
    }

    private func renderedSummary(_ raw: String) -> AttributedString? {
        try? AttributedString(markdown: raw,
                              options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

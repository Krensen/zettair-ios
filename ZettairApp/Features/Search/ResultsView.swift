import SwiftUI
import ZettairKit

struct ResultsView: View {
    let response: SearchResponse
    let query: String
    let onTapResult: (SearchResult) -> Void
    let onTapRelated: (RelatedItem) -> Void

    @EnvironmentObject var environment: AppEnvironment
    @State private var citeTarget: SearchResult? = nil
    @State private var safariURL: URL? = nil

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                CurrentSearchHeader(
                    query: query,
                    totalResults: response.total,
                    tookMs: response.tookMs
                )
                if let summary = response.summary {
                    KnowledgePanelCard(
                        title: response.results.first?.displayTitle ?? query,
                        markdown: summary,
                        kind: response.summaryKind ?? .biographical,
                        eventDate: response.eventDate,
                        imageURL: response.results.first?.imageURL.flatMap { ImageProxy.url(for: $0, preferredWidth: 330) }
                    )
                }
                ForEach(response.results) { result in
                    ResultRow(
                        result: result,
                        onTap: {
                            safariURL = URL(string: result.url)
                            onTapResult(result)
                        },
                        onCite: { citeTarget = result },
                        onSave: { environment.savedStore.saveArticle(docno: result.docno) }
                    )
                    Divider()
                }
                if let related = response.related, !related.items.isEmpty {
                    RelatedEntitiesPanel(block: related, onTap: onTapRelated)
                        .padding(.top, 8)
                }
                FooterAttribution()
                    .padding(.top, 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .sheet(item: $citeTarget) { result in
            CiteThisSheet(title: result.displayTitle, url: result.url)
        }
        .sheet(item: Binding<IdentifiableURL?>(
            get: { safariURL.map(IdentifiableURL.init) },
            set: { safariURL = $0?.url }
        )) { wrapped in
            SafariView(url: wrapped.url)
        }
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// Small banner at the top of the results showing what query produced
/// them, how many hits, and how long the engine took. Needed because the
/// .searchable field's nav-bar drawer collapses to its prompt placeholder
/// when not focused, so the active query isn't otherwise visible.
private struct CurrentSearchHeader: View {
    let query: String
    let totalResults: Int
    let tookMs: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(query)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(stats)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var stats: String {
        let n = totalResults.formatted()
        let ms = String(format: "%.0f", tookMs)
        return "\(n) results · \(ms) ms"
    }
}

private struct FooterAttribution: View {
    var body: some View {
        Text("Content from English Wikipedia, licensed CC BY-SA. Knowledge-panel summaries are derived from Wikipedia article text.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
    }
}

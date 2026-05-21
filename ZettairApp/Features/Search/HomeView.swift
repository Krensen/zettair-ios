import SwiftUI
import ZettairKit

/// The empty-search home state. Large italic wordmark, Paul-Smith stripe,
/// and a trending chip rail below — mirrors zettair.io's homepage.
struct HomeView: View {
    let trending: TrendingResponse?
    let trendingThumbs: [String: URL]
    let onTapTrending: (TrendingItem) -> Void
    let logoNamespace: Namespace.ID

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 60)
                ZettairHero(namespace: logoNamespace)
                Text("Search 1.5M Wikipedia articles")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let t = trending, !t.items.isEmpty {
                    TrendingListView(response: t, thumbs: trendingThumbs, onTap: onTapTrending)
                        .padding(.top, 12)
                        .padding(.horizontal)
                }
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// While-typing state. A vertical list of suggestion rows.
struct SuggestionsView: View {
    let suggestions: [Suggestion]
    let onTapSuggestion: (Suggestion) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if suggestions.isEmpty {
                    Spacer().frame(height: 80)
                    Text("No suggestions yet — keep typing")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(suggestions) { s in
                        Button(action: {
                            Haptics.tap()
                            onTapSuggestion(s)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                Text(s.query)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.footnote)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }
}

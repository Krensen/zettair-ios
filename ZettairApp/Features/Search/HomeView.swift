import SwiftUI
import ZettairKit

/// Home / empty-search state. Shows the trending chip rail and, while typing,
/// suggestion rows from `/suggest`. Mirrors zettair.io's homepage in shape.
struct HomeView: View {
    let trending: TrendingResponse?
    let suggestions: [Suggestion]
    let onTapTrending: (TrendingItem) -> Void
    let onTapSuggestion: (Suggestion) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !suggestions.isEmpty {
                    SuggestionListView(suggestions: suggestions, onTap: onTapSuggestion)
                }
                if let t = trending, !t.items.isEmpty {
                    TrendingRailView(response: t, onTap: onTapTrending)
                }
                if suggestions.isEmpty && (trending?.items.isEmpty ?? true) {
                    Spacer(minLength: 80)
                    ContentUnavailableView(
                        "Search Wikipedia",
                        systemImage: "magnifyingglass",
                        description: Text("Start typing to search 1.5M articles.")
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

private struct SuggestionListView: View {
    let suggestions: [Suggestion]
    let onTap: (Suggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions) { s in
                Button(action: { onTap(s) }) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text(s.query)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
    }
}

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
                    EmptyHomeView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

private struct EmptyHomeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Search Wikipedia")
                .font(.headline)
            Text("Start typing to search 1.5M articles.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
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

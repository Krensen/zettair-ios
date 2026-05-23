import SwiftUI
import ZettairKit

/// Shown above the underlying content while the user is focused on the
/// search field. Mirrors iOS Settings' active-search state:
///   - Empty draft → 4-up grid of "Suggestions" (we use trending items
///                   with their thumbnails)
///   - Non-empty draft → vertical list of /suggest matches
///
/// The view is placed in a ZStack above `contentLayer` with .opacity
/// transitions, controlled by SwiftUI's `\.isSearching` env value via the
/// parent. The underlying view model state (.results, .idle, etc.) is
/// untouched — when the user taps Cancel the overlay disappears and the
/// previous state re-renders. No state machine tricks.
struct ActiveSearchView: View {
    let draft: String
    let trending: TrendingResponse?
    let trendingThumbs: [String: URL]
    let suggestions: [Suggestion]
    let onTapTrending: (TrendingItem) -> Void
    let onTapSuggestion: (Suggestion) -> Void

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if trimmedDraft.isEmpty {
            TrendingSuggestionGrid(
                trending: trending,
                thumbs: trendingThumbs,
                onTap: onTapTrending
            )
        } else {
            QuerySuggestionList(
                suggestions: suggestions,
                onTap: onTapSuggestion
            )
        }
    }
}

// MARK: - Trending grid (empty draft)

private struct TrendingSuggestionGrid: View {
    let trending: TrendingResponse?
    let thumbs: [String: URL]
    let onTap: (TrendingItem) -> Void

    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Suggestions")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal)
                if let items = trending?.items, !items.isEmpty {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(items.prefix(8)) { item in
                            Button {
                                Haptics.tap()
                                onTap(item)
                            } label: {
                                GridSuggestion(item: item, thumb: thumbs[item.query])
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("Nothing trending right now.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 12)
        }
    }
}

private struct GridSuggestion: View {
    let item: TrendingItem
    let thumb: URL?

    var body: some View {
        VStack(spacing: 6) {
            tileImage
            Text(item.title)
                .font(.caption2)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var tileImage: some View {
        if let thumb {
            SmartImageView(
                url: thumb,
                size: CGSize(width: 64, height: 64),
                cornerRadius: 14
            )
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(
                    colors: [tileColor.opacity(0.85), tileColor.opacity(0.55)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(letterPair)
                        .font(.custom("Georgia-Italic", size: 26))
                        .foregroundStyle(.white)
                        .tracking(-1)
                )
        }
    }

    private var letterPair: String {
        let first = item.title.split(separator: " ").first.map(String.init) ?? item.title
        return String(first.prefix(2)).uppercased()
    }

    private var tileColor: Color {
        let h = abs(item.title.hashValue)
        return BrandStripe.colors[h % BrandStripe.colors.count]
    }
}

// MARK: - Suggestion list (non-empty draft)

private struct QuerySuggestionList: View {
    let suggestions: [Suggestion]
    let onTap: (Suggestion) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if suggestions.isEmpty {
                    Text("No suggestions yet — keep typing")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 80)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(suggestions) { s in
                        Button {
                            Haptics.tap()
                            onTap(s)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                Text(s.query).foregroundStyle(.primary)
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
                        Divider().padding(.leading, 44)
                    }
                }
            }
        }
    }
}

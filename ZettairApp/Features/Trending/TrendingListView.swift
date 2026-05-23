import SwiftUI
import ZettairKit

/// Replaces the horizontal chip rail with a vertical list on the homepage.
/// iPhones have plenty of vertical real estate below the hero; a list uses
/// it for scannability instead of cramming 6 truncated chips into one row.
///
/// Thumbnails are fetched via /search?q=<query>&n=1 in SearchViewModel and
/// passed in keyed by query. While a thumbnail is loading or missing, we
/// fall back to a branded letter tile.
struct TrendingListView: View {
    let response: TrendingResponse
    let thumbs: [String: URL]
    let onTap: (TrendingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            VStack(spacing: 0) {
                ForEach(Array(response.items.enumerated()), id: \.element.id) { idx, item in
                    Button(action: {
                        Haptics.tap()
                        onTap(item)
                    }) {
                        TrendingRow(item: item, thumb: thumbs[item.query])
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if idx < response.items.count - 1 {
                        Divider().padding(.leading, 14 + 56 + 14)
                    }
                }
            }
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: response.mode == "spike" ? "flame.fill" : "chart.bar.xaxis")
                .foregroundStyle(.orange)
            Text(response.mode == "spike" ? "Trending now" : "Popular now")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 14)
    }
}

private struct TrendingRow: View {
    let item: TrendingItem
    let thumb: URL?

    var body: some View {
        HStack(spacing: 14) {
            ThumbnailOrTile(title: item.title, url: thumb)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let badge = sourceBadge(for: item.source) {
                    Text(badge.text)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(badge.color.opacity(0.15), in: Capsule())
                        .foregroundStyle(badge.color)
                }
            }
            Spacer(minLength: 8)
            trailingIcon
                .foregroundStyle(item.inIndex ? Color.secondary : Color.orange)
                .font(.footnote)
        }
    }

    private var trailingIcon: some View {
        Image(systemName: item.inIndex ? "chevron.right" : "arrow.up.forward.app")
    }

    private struct Badge { let text: String; let color: Color }
    private func sourceBadge(for source: String) -> Badge? {
        switch source {
        case "google_news": return Badge(text: "News",      color: .blue)
        case "wiki_itn":    return Badge(text: "Wikipedia", color: .purple)
        case "spike":       return Badge(text: "Spike",     color: .orange)
        default:            return nil
        }
    }
}

/// Tries to load a real thumbnail; falls back to a letter tile while loading
/// or on failure. The letter-tile fallback also stays put if the search has
/// no image_url (we'll never know, but the visual is consistent).
private struct ThumbnailOrTile: View {
    let title: String
    let url: URL?

    var body: some View {
        if let url {
            SmartImageView(
                url: url,
                size: CGSize(width: 56, height: 56),
                cornerRadius: 10,
                failureView: { BrandLetterTile(title: title, size: 56, cornerRadius: 10) }
            )
        } else {
            BrandLetterTile(title: title, size: 56, cornerRadius: 10)
        }
    }
}

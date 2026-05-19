import SwiftUI
import ZettairKit

struct TrendingRailView: View {
    let response: TrendingResponse
    let onTap: (TrendingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: response.mode == "spike" ? "flame.fill" : "chart.bar.xaxis")
                    .foregroundStyle(.orange)
                Text(response.mode == "spike" ? "Trending now" : "Popular now")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(response.items) { item in
                        TrendingChip(item: item, onTap: onTap)
                    }
                }
            }
        }
    }
}

private struct TrendingChip: View {
    let item: TrendingItem
    let onTap: (TrendingItem) -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            onTap(item)
        }) {
            HStack(spacing: 6) {
                Image(systemName: item.inIndex ? "magnifyingglass" : "arrow.up.forward.app")
                    .font(.caption2)
                    .foregroundStyle(item.inIndex ? Color.accentColor : Color.orange)
                Text(item.title)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(Color.secondary.opacity(0.12))
            )
            .overlay(
                Capsule().stroke(Color.secondary.opacity(0.18), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

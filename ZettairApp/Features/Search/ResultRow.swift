import SwiftUI
import ZettairKit

struct ResultRow: View {
    let result: SearchResult
    let onTap: () -> Void
    let onCite: () -> Void
    let onSave: () -> Void

    var body: some View {
        Button(action: tap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Text(result.url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    SnippetText(html: result.snippet)
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.85))
                        .lineLimit(3)
                    pills
                }
                if let s = result.imageURL, let url = URL(string: s) {
                    Thumbnail(url: url)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open", systemImage: "safari", action: tap)
            Button("Save", systemImage: "bookmark", action: onSave)
            Button("Cite this", systemImage: "quote.bubble", action: onCite)
            ShareLink(item: URL(string: result.url) ?? URL(string: "https://zettair.io")!) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .swipeActions(edge: .trailing) {
            Button { onSave() } label: { Label("Save", systemImage: "bookmark") }
                .tint(.blue)
        }
    }

    private func tap() {
        Haptics.tap()
        onTap()
    }

    private var pills: some View {
        HStack(spacing: 8) {
            if let mins = result.readingTimeMin {
                Pill(text: "\(mins) min read", system: "book")
            }
            if let d = result.difficulty {
                Pill(text: d.capitalized, system: "scope")
            }
        }
    }
}

private struct Thumbnail: View {
    let url: URL
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            default:
                Color.secondary.opacity(0.15)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct Pill: View {
    let text: String
    let system: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: system).font(.caption2)
            Text(text).font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.12), in: Capsule())
        .foregroundStyle(.secondary)
    }
}

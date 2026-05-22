import SwiftUI
import ZettairKit

/// Mirrors the PRD-018 knowledge panel from index.html — title, body markdown,
/// and a kind-specific badge. News-kind panels carry an event date pill. We
/// use SwiftUI's built-in markdown rendering (LocalizedStringKey accepts
/// Markdown directly) which handles **bold** and *italic* without a third-party
/// package; if richer markdown is required later, drop in swift-markdown-ui.
struct KnowledgePanelCard: View {
    let title: String
    let markdown: String
    let kind: SearchResponse.SummaryKind
    let eventDate: String?
    let imageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .lineLimit(2)
                        kindBadge
                    }
                    if let body = renderedMarkdown {
                        Text(body)
                            .font(.body)
                            .foregroundStyle(.primary)
                    } else {
                        Text(markdown).font(.body)
                    }
                    if kind == .news, let d = eventDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            Text(formatEventDate(d))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                if let url = imageURL {
                    SmartImageView(url: url, size: CGSize(width: 90, height: 90), cornerRadius: 10)
                }
            }
            attribution
        }
        .padding(14)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var renderedMarkdown: AttributedString? {
        try? AttributedString(markdown: markdown, options: .init(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        ))
    }

    private var kindBadge: some View {
        Group {
            switch kind {
            case .biographical:
                Label("Knowledge", systemImage: "sparkles")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(.tint)
            case .news:
                Label("News", systemImage: "newspaper")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }
        }
    }

    private var attribution: some View {
        Text("Summary derived from Wikipedia · CC BY-SA")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private func formatEventDate(_ raw: String) -> String {
        // Server stores ISO-ish "YYYY-MM-DD"; display as a human date.
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        if let date = f.date(from: raw) {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .none
            return df.string(from: date)
        }
        return raw
    }
}

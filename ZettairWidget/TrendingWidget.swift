import WidgetKit
import SwiftUI
import ZettairKit

// PRD-028 M7: full widget implementation. M1–M5 ships a placeholder so the
// project builds end-to-end with the widget target wired in. Wiring includes
// the timeline provider, App Group sharing, and a simple SwiftUI view that
// can be extended in M7.

struct TrendingEntry: TimelineEntry {
    let date: Date
    let items: [TrendingItem]
    let mode: String
}

struct TrendingProvider: TimelineProvider {
    private let api = ZettairAPI()

    func placeholder(in context: Context) -> TrendingEntry {
        TrendingEntry(date: Date(), items: [], mode: "raw")
    }

    func getSnapshot(in context: Context, completion: @escaping (TrendingEntry) -> Void) {
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrendingEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            // Refresh every 3 hours to match the server-side fetcher cadence.
            let next = Calendar.current.date(byAdding: .hour, value: 3, to: entry.date) ?? entry.date
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchEntry() async -> TrendingEntry {
        do {
            let r = try await api.trending(n: 6)
            return TrendingEntry(date: Date(), items: r.items, mode: r.mode)
        } catch {
            return TrendingEntry(date: Date(), items: [], mode: "raw")
        }
    }
}

struct TrendingWidgetView: View {
    let entry: TrendingEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: entry.mode == "spike" ? "flame.fill" : "chart.bar.xaxis")
                    .foregroundStyle(.orange)
                Text(entry.mode == "spike" ? "Trending" : "Popular")
                    .font(.caption.weight(.semibold))
            }
            if entry.items.isEmpty {
                Spacer()
                Text("Tap to open Zettair")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.items.prefix(maxItems), id: \.query) { item in
                    Link(destination: URL(string: "zettair://search?q=\(item.query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.query)")!) {
                        Text(item.title)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }

    private var maxItems: Int {
        switch family {
        case .systemSmall:  return 1
        case .systemMedium: return 3
        case .systemLarge:  return 6
        default:            return 3
        }
    }
}

struct TrendingWidget: Widget {
    let kind: String = "io.zettair.app.widget.trending"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrendingProvider()) { entry in
            TrendingWidgetView(entry: entry)
        }
        .configurationDisplayName("Trending on Zettair")
        .description("What's spiking on Wikipedia right now.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

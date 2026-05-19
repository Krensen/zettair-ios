import Foundation
import CoreSpotlight
import ZettairKit

/// Indexes top-N popular queries (sourced from /suggest with a single-letter
/// prefix sweep) and any query the user has run, so iOS Spotlight can offer
/// them inline with system search results.
///
/// We don't have an autosuggest dump on the device — keeping a 27 MB JSON in
/// app bundle is overkill. Instead we seed Spotlight from /suggest itself on
/// first launch by sweeping a few high-value prefixes ("a", "the", "ein"...)
/// and persist what we've indexed. Subsequent launches refresh the in-flight
/// query history.
@MainActor
final class SpotlightIndexer {
    static let shared = SpotlightIndexer()

    private let defaults = UserDefaults.standard
    private let kSeeded = "spotlight.seeded.v1"
    private let domain  = "io.zettair.app.queries"

    func ensureSeeded(api: ZettairAPI) async {
        guard !defaults.bool(forKey: kSeeded) else { return }
        // PRD-028 M5: a hand-picked prefix sweep is enough for a first pass.
        // We keep the count small (~500 queries) because Spotlight dedups
        // by uniqueIdentifier and over-indexing dilutes rank.
        let prefixes = ["the", "ein", "wor", "mar", "uni", "lon", "nat", "rev",
                        "fre", "ame", "his", "pol", "sci", "art", "bio", "geo",
                        "rom", "egy", "phi", "wri", "mus", "com", "tec", "wik"]
        var items: [CSSearchableItem] = []
        for p in prefixes {
            do {
                let r = try await api.suggest(p, n: 25)
                for s in r.suggestions {
                    items.append(makeItem(query: s.query, popularity: s.count))
                }
            } catch {
                continue
            }
            if items.count > 600 { break }
        }
        guard !items.isEmpty else { return }
        do {
            try await CSSearchableIndex.default().indexSearchableItems(items)
            defaults.set(true, forKey: kSeeded)
        } catch {
            // Spotlight indexing failures are not fatal.
        }
    }

    func indexUserQuery(_ q: String) {
        let item = makeItem(query: q, popularity: 100_000)
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    private func makeItem(query: String, popularity: Int) -> CSSearchableItem {
        let attrs = CSSearchableItemAttributeSet(itemContentType: "public.text")
        attrs.title = query
        attrs.contentDescription = "Search Wikipedia via Zettair"
        attrs.keywords = [query, "wikipedia", "zettair"]
        attrs.rankingHint = NSNumber(value: max(1, popularity))
        let item = CSSearchableItem(uniqueIdentifier: "query:\(queryNorm(query))",
                                    domainIdentifier: domain,
                                    attributeSet: attrs)
        return item
    }
}

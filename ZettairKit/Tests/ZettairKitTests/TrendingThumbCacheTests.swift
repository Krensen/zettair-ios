import XCTest
@testable import ZettairKit

final class TrendingThumbCacheTests: XCTestCase {
    private func freshFilename() -> String {
        "trending_thumbs_test_\(UUID().uuidString).json"
    }

    func testRoundTrip() async {
        let name = freshFilename()
        let c1 = TrendingThumbCache(filename: name)
        await c1.put("openai", URL(string: "https://example.com/o.png")!)
        await c1.put("iran",   URL(string: "https://example.com/i.png")!)

        let c2 = TrendingThumbCache(filename: name)
        let snap = await c2.snapshot()
        XCTAssertEqual(snap.count, 2)
        XCTAssertEqual(snap["openai"]?.absoluteString, "https://example.com/o.png")
        await c2.clear()
    }

    func testExpiryDropsStaleEntries() async {
        let name = freshFilename()
        // Build a cache with a 0-hour freshness window; everything is stale.
        let c = TrendingThumbCache(filename: name, freshnessHours: 0)
        await c.put("x", URL(string: "https://example.com/x.png")!)
        let snap = await c.snapshot()
        XCTAssertEqual(snap.count, 0)
        await c.clear()
    }

    func testPutAllBatches() async {
        let name = freshFilename()
        let c = TrendingThumbCache(filename: name)
        await c.putAll([
            ("a", URL(string: "https://e/a")!),
            ("b", URL(string: "https://e/b")!),
            ("c", URL(string: "https://e/c")!),
        ])
        let snap = await c.snapshot()
        XCTAssertEqual(snap.count, 3)
        await c.clear()
    }
}

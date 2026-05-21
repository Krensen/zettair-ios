import XCTest
@testable import ZettairKit

final class ImageProxyTests: XCTestCase {
    func testRewritesStandardThumb() {
        let input = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Albert_Einstein_Head_cleaned.jpg/300px-Albert_Einstein_Head_cleaned.jpg"
        let expected = "https://upload.wikimedia.org/wikipedia/commons/2/28/Albert_Einstein_Head_cleaned.jpg"
        XCTAssertEqual(ImageProxy.rewriteWikimediaThumbToOriginal(input), expected)
    }

    func testPassesThroughNonThumb() {
        let input = "https://upload.wikimedia.org/wikipedia/commons/d/d3/Albert_Einstein_Head.jpg"
        XCTAssertEqual(ImageProxy.rewriteWikimediaThumbToOriginal(input), input)
    }

    func testHandlesArbitraryThumbWidth() {
        let input = "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/X.jpg/640px-X.jpg"
        let expected = "https://upload.wikimedia.org/wikipedia/commons/f/f4/X.jpg"
        XCTAssertEqual(ImageProxy.rewriteWikimediaThumbToOriginal(input), expected)
    }

    func testProducesProxyURL() {
        let raw = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Foo.jpg/300px-Foo.jpg"
        let proxied = ImageProxy.url(for: raw)
        XCTAssertNotNil(proxied)
        XCTAssertEqual(proxied?.host, "zettair.io")
        XCTAssertEqual(proxied?.path, "/img")
        // The URL query should contain the rewritten (non-thumb) value.
        let q = proxied?.query ?? ""
        XCTAssertTrue(q.contains("commons/2/28/Foo.jpg"), q)
        XCTAssertFalse(q.contains("thumb"), q)
        XCTAssertFalse(q.contains("300px"), q)
    }

    func testEmptyReturnsNil() {
        XCTAssertNil(ImageProxy.url(for: ""))
    }
}

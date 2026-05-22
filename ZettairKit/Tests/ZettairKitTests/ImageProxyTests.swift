import XCTest
@testable import ZettairKit

final class ImageProxyTests: XCTestCase {

    // MARK: width allowlist

    func testAllowedWidthRoundsUp() {
        XCTAssertEqual(ImageProxy.allowedWidth(for: 1),    20)
        XCTAssertEqual(ImageProxy.allowedWidth(for: 20),   20)
        XCTAssertEqual(ImageProxy.allowedWidth(for: 21),   40)
        XCTAssertEqual(ImageProxy.allowedWidth(for: 168),  250)  // 56pt @ 3x
        XCTAssertEqual(ImageProxy.allowedWidth(for: 250),  250)
        XCTAssertEqual(ImageProxy.allowedWidth(for: 251),  330)
        XCTAssertEqual(ImageProxy.allowedWidth(for: 270),  330)  // 90pt @ 3x
        XCTAssertEqual(ImageProxy.allowedWidth(for: 500),  500)
        XCTAssertEqual(ImageProxy.allowedWidth(for: 9999), 3840) // saturates
    }

    // MARK: URL rewriting

    func testRewrites300pxTo250pxAtDefault() {
        let input = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Albert_Einstein_Head_cleaned.jpg/300px-Albert_Einstein_Head_cleaned.jpg"
        let expected = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Albert_Einstein_Head_cleaned.jpg/250px-Albert_Einstein_Head_cleaned.jpg"
        XCTAssertEqual(ImageProxy.rewriteToAllowedThumbWidth(input, preferredWidth: 250), expected)
    }

    func testRewrites300pxTo330pxForKnowledgePanel() {
        let input = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Foo.jpg/300px-Foo.jpg"
        let expected = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Foo.jpg/330px-Foo.jpg"
        XCTAssertEqual(ImageProxy.rewriteToAllowedThumbWidth(input, preferredWidth: 330), expected)
    }

    func testKeepsAlreadyAllowedWidth() {
        let input = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Foo.jpg/250px-Foo.jpg"
        XCTAssertEqual(ImageProxy.rewriteToAllowedThumbWidth(input, preferredWidth: 250), input)
    }

    func testHandlesSVGPng() {
        let input = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Flag.svg/300px-Flag.svg.png"
        let expected = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Flag.svg/250px-Flag.svg.png"
        XCTAssertEqual(ImageProxy.rewriteToAllowedThumbWidth(input, preferredWidth: 250), expected)
    }

    func testPassesThroughNonThumb() {
        let input = "https://upload.wikimedia.org/wikipedia/commons/d/d3/Albert_Einstein_Head.jpg"
        XCTAssertEqual(ImageProxy.rewriteToAllowedThumbWidth(input, preferredWidth: 250), input)
    }

    // MARK: proxy URL

    func testProducesProxyURLWithRewrittenWidth() {
        let raw = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Foo.jpg/300px-Foo.jpg"
        let proxied = ImageProxy.url(for: raw)
        XCTAssertNotNil(proxied)
        XCTAssertEqual(proxied?.host, "zettair.io")
        XCTAssertEqual(proxied?.path, "/img")
        let q = proxied?.query ?? ""
        XCTAssertTrue(q.contains("250px-Foo.jpg"), q)
        XCTAssertFalse(q.contains("300px"), q)
    }

    func testEmptyReturnsNil() {
        XCTAssertNil(ImageProxy.url(for: ""))
    }
}

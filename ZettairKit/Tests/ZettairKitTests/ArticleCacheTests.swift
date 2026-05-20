import XCTest
@testable import ZettairKit

final class ArticleCacheTests: XCTestCase {
    func testPutAndGet() async {
        let c = InMemoryArticleCache()
        let a = ArticleResponse(docno: "A", title: "A", body: "x", url: "u", imageURL: nil)
        await c.put(a)
        let got = await c.get("A")
        XCTAssertEqual(got, a)
    }

    func testLRUEviction() async {
        let c = InMemoryArticleCache(maxEntries: 2)
        await c.put(ArticleResponse(docno: "A", title: "A", body: "", url: "", imageURL: nil))
        await c.put(ArticleResponse(docno: "B", title: "B", body: "", url: "", imageURL: nil))
        _ = await c.get("A")  // promote A
        await c.put(ArticleResponse(docno: "C", title: "C", body: "", url: "", imageURL: nil))  // evicts B
        let a = await c.get("A")
        let b = await c.get("B")
        let cc = await c.get("C")
        XCTAssertNotNil(a)
        XCTAssertNil(b)
        XCTAssertNotNil(cc)
    }

    func testClear() async {
        let c = InMemoryArticleCache()
        await c.put(ArticleResponse(docno: "A", title: "A", body: "", url: "", imageURL: nil))
        await c.clear()
        let n = await c.size()
        XCTAssertEqual(n, 0)
    }
}

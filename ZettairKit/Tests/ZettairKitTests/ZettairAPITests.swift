import XCTest
@testable import ZettairKit

final class ZettairAPITests: XCTestCase {

    override func tearDown() {
        StubURLProtocol.responder = nil
        super.tearDown()
    }

    private func fixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
              ?? Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: "json")
        guard let url else {
            XCTFail("missing fixture \(name).json")
            throw URLError(.fileDoesNotExist)
        }
        return try Data(contentsOf: url)
    }

    // MARK: search

    func testSearchDecodesFullResponse() async throws {
        let data = try fixture("search")
        StubURLProtocol.responder = { req in
            XCTAssertEqual(req.url?.path, "/search")
            XCTAssertEqual(req.url?.query, "q=einstein&n=5")
            return StubURLProtocol.ok(url: req.url!, body: data)
        }
        let api = ZettairAPI(baseURL: URL(string: "https://zettair.test")!,
                              session: StubURLProtocol.session())
        let resp = try await api.search("einstein", n: 5)

        XCTAssertEqual(resp.query, "einstein")
        XCTAssertEqual(resp.total, 423)
        XCTAssertEqual(resp.results.count, 2)
        XCTAssertEqual(resp.results.first?.docno, "Albert_Einstein")
        XCTAssertEqual(resp.results.first?.displayTitle, "Albert Einstein")
        XCTAssertEqual(resp.summaryKind, .biographical)
        XCTAssertEqual(resp.related?.sourceClass, "human")
        XCTAssertEqual(resp.related?.items.count, 2)
        XCTAssertEqual(resp.results[1].imageURL, nil)
        XCTAssertEqual(resp.results[0].readingTimeMin, 12)
        XCTAssertEqual(resp.results[0].difficulty, "intermediate")
    }

    func testSearchRejectsEmptyQuery() async {
        let api = ZettairAPI(baseURL: URL(string: "https://zettair.test")!,
                              session: StubURLProtocol.session())
        do {
            _ = try await api.search("   ")
            XCTFail("expected error")
        } catch let err as ZettairAPIError {
            XCTAssertEqual(err, .emptyQuery)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testSearchSurfacesServerError() async throws {
        let body = #"{"error":"Empty query"}"#.data(using: .utf8)!
        StubURLProtocol.responder = { req in
            StubURLProtocol.status(400, url: req.url!, body: body)
        }
        let api = ZettairAPI(baseURL: URL(string: "https://zettair.test")!,
                              session: StubURLProtocol.session())
        do {
            _ = try await api.search("ok")
            XCTFail("expected throw")
        } catch let err as ZettairAPIError {
            if case .server(let msg) = err {
                XCTAssertEqual(msg, "Empty query")
            } else {
                XCTFail("wrong error \(err)")
            }
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    // MARK: suggest

    func testSuggest() async throws {
        let data = try fixture("suggest")
        StubURLProtocol.responder = { req in
            XCTAssertEqual(req.url?.path, "/suggest")
            return StubURLProtocol.ok(url: req.url!, body: data)
        }
        let api = ZettairAPI(baseURL: URL(string: "https://zettair.test")!,
                              session: StubURLProtocol.session())
        let resp = try await api.suggest("ein")
        XCTAssertEqual(resp.suggestions.count, 3)
        XCTAssertEqual(resp.suggestions.first?.query, "einstein")
        XCTAssertEqual(resp.suggestions.first?.count, 4810)
    }

    func testSuggestEmptyReturnsEmpty() async throws {
        // Empty query short-circuits without a network call.
        StubURLProtocol.responder = { _ in
            XCTFail("network should not be touched")
            return StubURLProtocol.status(500, url: URL(string: "x:/")!)
        }
        let api = ZettairAPI(baseURL: URL(string: "https://zettair.test")!,
                              session: StubURLProtocol.session())
        let resp = try await api.suggest("   ")
        XCTAssertEqual(resp.suggestions.count, 0)
    }

    // MARK: trending

    func testTrending() async throws {
        let data = try fixture("trending")
        StubURLProtocol.responder = { req in
            XCTAssertEqual(req.url?.path, "/api/trending")
            return StubURLProtocol.ok(url: req.url!, body: data)
        }
        let api = ZettairAPI(baseURL: URL(string: "https://zettair.test")!,
                              session: StubURLProtocol.session())
        let resp = try await api.trending(n: 8)
        XCTAssertEqual(resp.mode, "spike")
        XCTAssertEqual(resp.items.count, 2)
        XCTAssertTrue(resp.items[0].inIndex)
        XCTAssertFalse(resp.items[1].inIndex)
        XCTAssertEqual(resp.items[1].wikiURL, "https://en.wikipedia.org/wiki/Fresh_News_Article_2026")
    }

    // MARK: click

    func testClickIsFireAndForget() async {
        StubURLProtocol.responder = { req in
            XCTAssertEqual(req.httpMethod, "POST")
            XCTAssertEqual(req.url?.path, "/click")
            return StubURLProtocol.status(500, url: req.url!)
        }
        let api = ZettairAPI(baseURL: URL(string: "https://zettair.test")!,
                              session: StubURLProtocol.session())
        // Should not throw despite 500.
        await api.click(ClickEvent(q: "einstein", docno: "Albert_Einstein", rank: 1, score: 16.4))
    }
}

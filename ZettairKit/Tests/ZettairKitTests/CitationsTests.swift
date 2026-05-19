import XCTest
@testable import ZettairKit

final class CitationsTests: XCTestCase {
    private let fixed: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 19
        c.hour = 12; c.minute = 0; c.second = 0
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    func testProducesFiveStyles() {
        let cs = Citations.build(title: "Mark Carney", url: "https://en.wikipedia.org/wiki/Mark_Carney", now: fixed)
        XCTAssertEqual(cs.count, 5)
        XCTAssertEqual(cs.map { $0.style }, [.apa, .mla, .chicago, .harvard, .bibtex])
    }

    func testAPAFormat() {
        let cs = Citations.build(title: "Mark Carney", url: "https://en.wikipedia.org/wiki/Mark_Carney", now: fixed)
        let apa = cs.first(where: { $0.style == .apa })!.text
        XCTAssertTrue(apa.contains("(2026, May 19)"), apa)
        XCTAssertTrue(apa.contains("Mark Carney"), apa)
        XCTAssertTrue(apa.contains("Retrieved May 19, 2026"), apa)
        XCTAssertTrue(apa.hasSuffix("https://en.wikipedia.org/wiki/Mark_Carney"), apa)
    }

    func testMLAFormat() {
        let mla = Citations.build(title: "T", url: "https://x/T", now: fixed).first { $0.style == .mla }!.text
        XCTAssertTrue(mla.contains("19 May 2026"), mla)
        XCTAssertTrue(mla.contains("\"T.\""), mla)
    }

    func testHarvardFormat() {
        let h = Citations.build(title: "T", url: "https://x/T", now: fixed).first { $0.style == .harvard }!.text
        XCTAssertTrue(h.contains("(2026)"), h)
        XCTAssertTrue(h.contains("Accessed: 19 May 2026"), h)
    }

    func testBibTeXFormat() {
        let bib = Citations.build(title: "Mark Carney",
                                   url: "https://en.wikipedia.org/wiki/Mark_Carney",
                                   now: fixed).first { $0.style == .bibtex }!.text
        XCTAssertTrue(bib.hasPrefix("@misc{wiki:Mark_Carney"), bib)
        XCTAssertTrue(bib.contains("year         = \"2026\""), bib)
        XCTAssertTrue(bib.contains("[Online; accessed 19 May 2026]"), bib)
    }
}

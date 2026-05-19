import XCTest
@testable import ZettairKit

final class QueryNormTests: XCTestCase {
    func testLowercases() {
        XCTAssertEqual(queryNorm("Einstein"), "einstein")
    }
    func testTrims() {
        XCTAssertEqual(queryNorm("  hello  "), "hello")
    }
    func testCollapsesInnerWhitespace() {
        XCTAssertEqual(queryNorm("Mark   Carney"), "mark carney")
    }
    func testCollapsesMixedWhitespace() {
        XCTAssertEqual(queryNorm("\tmark \n carney "), "mark carney")
    }
    func testEmptyStaysEmpty() {
        XCTAssertEqual(queryNorm(""), "")
        XCTAssertEqual(queryNorm("   "), "")
    }
}

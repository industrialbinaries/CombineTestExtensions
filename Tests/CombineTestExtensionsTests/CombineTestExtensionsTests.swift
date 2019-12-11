import XCTest
@testable import CombineTestExtensions

final class CombineTestExtensionsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CombineTestExtensions().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

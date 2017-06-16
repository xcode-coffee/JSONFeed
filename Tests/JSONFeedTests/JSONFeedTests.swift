import XCTest
@testable import JSONFeed

class JSONFeedTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(JSONFeed().text, "Hello, World!")
    }


    static var allTests: [(String, (JSONFeedTests) -> () -> Void)] = [
        ("testExample", testExample),
    ]
}

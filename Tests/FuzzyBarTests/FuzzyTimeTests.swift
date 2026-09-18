import XCTest
@testable import FuzzyBar

final class FuzzyTimeTests: XCTestCase {
    func testPhrases() {
        XCTAssertEqual(FuzzyTime.phrase(hour: 20, minute: 40), "twenty to nine")
        XCTAssertEqual(FuzzyTime.phrase(hour: 20, minute: 38), "twenty to nine")
        XCTAssertEqual(FuzzyTime.phrase(hour: 20, minute: 37), "twenty-five to nine")
        XCTAssertEqual(FuzzyTime.phrase(hour: 9, minute: 0), "nine o'clock")
        XCTAssertEqual(FuzzyTime.phrase(hour: 9, minute: 2), "nine o'clock")
        XCTAssertEqual(FuzzyTime.phrase(hour: 9, minute: 3), "five past nine")
        XCTAssertEqual(FuzzyTime.phrase(hour: 9, minute: 15), "quarter past nine")
        XCTAssertEqual(FuzzyTime.phrase(hour: 9, minute: 30), "half past nine")
        XCTAssertEqual(FuzzyTime.phrase(hour: 9, minute: 45), "quarter to ten")
        XCTAssertEqual(FuzzyTime.phrase(hour: 11, minute: 58), "twelve o'clock")
        XCTAssertEqual(FuzzyTime.phrase(hour: 23, minute: 58), "twelve o'clock")
        XCTAssertEqual(FuzzyTime.phrase(hour: 0, minute: 10), "ten past twelve")
        XCTAssertEqual(FuzzyTime.phrase(hour: 12, minute: 50), "ten to one")
    }
}

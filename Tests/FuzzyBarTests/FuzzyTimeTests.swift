import XCTest
@testable import FuzzyBar

final class FuzzyTimeTests: XCTestCase {
    func testEveryMinuteRoundsToExpectedPhrase() {
        let hours = ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"]
        let prefixes = ["", "five past ", "ten past ", "quarter past ", "twenty past ", "twenty-five past ", "half past ", "twenty-five to ", "twenty to ", "quarter to ", "ten to ", "five to ", ""]
        for hour in 0..<24 {
            for minute in 0..<60 {
                let slot = (minute + 2) / 5
                let word = hours[(hour + (slot >= 7 ? 1 : 0)) % 12]
                let expected = slot == 0 || slot == 12 ? "\(word) o'clock" : prefixes[slot] + word
                XCTAssertEqual(FuzzyTime.phrase(hour: hour, minute: minute), expected, "\(hour):\(minute)")
            }
        }
    }
}

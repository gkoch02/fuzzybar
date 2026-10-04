import XCTest
@testable import FuzzyBar

final class CalendarGridTests: XCTestCase {
    private func calendar(_ firstWeekday: Int = 1, zone: String = "UTC") -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        cal.firstWeekday = firstWeekday
        return cal
    }

    private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

    func testCalendarLeapDayAndWeekStarts() {
        for first in [1, 2, 7] {
            let cal = calendar(first)
            let weeks = CalendarGrid.weeks(containing: date("2024-02-15T12:00:00Z"), calendar: cal)
            XCTAssertEqual(weeks.count, 6)
            XCTAssertTrue(weeks.allSatisfy { $0.count == 7 })
            let days = weeks.flatMap { $0 }
            XCTAssertEqual(Set(days).count, 42)
            XCTAssertEqual(cal.component(.weekday, from: days[0]), first)
            let february = days.filter { cal.component(.month, from: $0) == 2 }
            XCTAssertEqual(february.count, 29)
            XCTAssertEqual(cal.component(.day, from: february.last!), 29)
        }
    }

    func testCalendarAcrossDaylightSavingAndYearBoundary() {
        let cal = calendar(2, zone: "America/Los_Angeles")
        for month in ["2024-03-15T12:00:00Z", "2024-12-15T12:00:00Z"] {
            let days = CalendarGrid.weeks(containing: date(month), calendar: cal).flatMap { $0 }
            for pair in zip(days, days.dropFirst()) {
                XCTAssertEqual(cal.dateComponents([.day], from: pair.0, to: pair.1).day, 1)
                XCTAssertEqual(cal.component(.hour, from: pair.1), 0)
            }
        }
    }
}

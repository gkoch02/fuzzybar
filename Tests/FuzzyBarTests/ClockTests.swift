import XCTest
@testable import FuzzyBar

final class ClockTests: XCTestCase {
    private func calendar(zone: String = "UTC") -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        return cal
    }

    private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

    @MainActor func testClockSchedulesPhraseAndMinuteBoundaries() {
        let cal = calendar()
        let cases = [("2024-01-01T08:00:30Z", "2024-01-01T08:03:00Z"),
                     ("2024-01-01T08:03:00Z", "2024-01-01T08:08:00Z"),
                     ("2024-01-01T23:57:59Z", "2024-01-01T23:58:00Z"),
                     ("2024-01-01T23:59:30Z", "2024-01-02T00:03:00Z")]
        for (start, expected) in cases {
            XCTAssertEqual(Clock.nextTick(after: date(start), popoverVisible: false, calendar: cal).timeIntervalSince(date(expected)), 0.05, accuracy: 0.001)
        }
        XCTAssertEqual(Clock.nextTick(after: date("2024-01-01T23:59:30Z"), popoverVisible: true, calendar: cal).timeIntervalSince(date("2024-01-02T00:00:00Z")), 0.05, accuracy: 0.001)
    }

    @MainActor func testClockScheduleAcrossDSTAndFractionalTimeZone() {
        for (zone, start) in [("America/Los_Angeles", "2024-03-10T09:59:30Z"),
                              ("America/Los_Angeles", "2024-11-03T08:59:30Z"),
                              ("Asia/Kathmandu", "2024-01-01T08:00:30Z")] {
            let cal = calendar(zone: zone)
            let initial = date(start)
            let tick = Clock.nextTick(after: initial, popoverVisible: false, calendar: cal)
            XCTAssertGreaterThan(tick, initial)
            XCTAssertLessThanOrEqual(tick.timeIntervalSince(initial), 300.05)
            XCTAssertNotEqual(FuzzyTime.phrase(for: initial, calendar: cal), FuzzyTime.phrase(for: tick, calendar: cal))
        }
    }

    @MainActor func testClockRefreshesOnOpeningAndExternalChanges() {
        var current = date("2024-01-01T08:00:00Z")
        let clock = Clock(dateProvider: { current }, defaults: scratchDefaults())
        current = current.addingTimeInterval(90)
        clock.setPopoverVisible(true)
        XCTAssertEqual(clock.now, current)
        current = current.addingTimeInterval(3600)
        clock.refresh()
        XCTAssertEqual(clock.now, current)
        clock.setPopoverVisible(false)
        XCTAssertEqual(clock.now, current)
    }
}

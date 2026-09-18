import XCTest
import ServiceManagement
@testable import FuzzyBar

final class ReviewRegressionTests: XCTestCase {
    private func calendar(_ firstWeekday: Int = 1, zone: String = "UTC") -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        cal.firstWeekday = firstWeekday
        return cal
    }

    private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

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
        let clock = Clock(dateProvider: { current })
        current = current.addingTimeInterval(90)
        clock.setPopoverVisible(true)
        XCTAssertEqual(clock.now, current)
        current = current.addingTimeInterval(3600)
        clock.refresh()
        XCTAssertEqual(clock.now, current)
        clock.setPopoverVisible(false)
        XCTAssertEqual(clock.now, current)
    }

    @MainActor func testPendingLoginApprovalAndExternalRefreshDoNotRegisterAgain() {
        var status = SMAppService.Status.notRegistered
        var registrations = 0
        var unregistrations = 0
        let login = LoginSettings(readStatus: { status }, register: {
            registrations += 1
            status = .requiresApproval
        }, unregister: {
            unregistrations += 1
            status = .notRegistered
        })
        login.setEnabled(true)
        XCTAssertFalse(login.isEnabled)
        XCTAssertEqual(login.status, .requiresApproval)
        XCTAssertNil(login.error)
        status = .enabled
        login.refresh()
        XCTAssertTrue(login.isEnabled)
        status = .requiresApproval
        login.refresh()
        XCTAssertFalse(login.isEnabled)
        XCTAssertEqual(registrations, 1)
        XCTAssertEqual(unregistrations, 0)
        login.setEnabled(false)
        XCTAssertEqual(login.status, .notRegistered)
        XCTAssertEqual(unregistrations, 1)
    }

    @MainActor func testFailedLoginChangeRestoresActualStateWithoutRetry() {
        enum Failure: Error { case denied }
        var calls = 0
        let login = LoginSettings(readStatus: { .enabled }, register: {}, unregister: {
            calls += 1
            throw Failure.denied
        })
        login.setEnabled(false)
        XCTAssertTrue(login.isEnabled)
        XCTAssertNotNil(login.error)
        XCTAssertEqual(calls, 1)
    }
}

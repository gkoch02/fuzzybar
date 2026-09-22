import XCTest
@testable import FuzzyBar

final class SpecialTimesTests: XCTestCase {
    private var cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal
    }()

    private func at(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ m: Int, _ s: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: m, second: s))!
    }

    private func text(_ date: Date, _ personality: Personality = .spoken, _ times: [SpecialTime] = []) -> String {
        Clock.text(for: date, calendar: cal, personality: personality, specialTimes: times)
    }

    func testHappyNewYearForTheFirstMinuteInEveryPersonality() {
        for personality in Personality.allCases {
            XCTAssertEqual(text(at(2027, 1, 1, 0, 0), personality), "Happy New Year!", "\(personality)")
            XCTAssertEqual(text(at(2027, 1, 1, 0, 0, 59), personality), "Happy New Year!", "\(personality)")
            XCTAssertEqual(text(at(2027, 1, 1, 0, 1), personality),
                           FuzzyTime.phrase(for: at(2027, 1, 1, 0, 1), calendar: cal, personality: personality))
            XCTAssertEqual(text(at(2026, 12, 31, 23, 59), personality),
                           FuzzyTime.phrase(for: at(2026, 12, 31, 23, 59), calendar: cal, personality: personality))
        }
        // Midnight on any other night is just midnight.
        XCTAssertEqual(text(at(2027, 1, 2, 0, 0)), "twelve o'clock")
    }

    /// The ticker has to wake for a one-minute message and again to clear it.
    @MainActor
    func testTicksIntoAndOutOfTheNewYear() {
        func tick(_ date: Date, _ personality: Personality = .spoken) -> Date {
            Clock.nextTick(after: date, popoverVisible: false, calendar: cal, personality: personality)
        }
        XCTAssertEqual(tick(at(2026, 12, 31, 23, 58, 10)), at(2027, 1, 1, 0, 0).addingTimeInterval(0.05))
        XCTAssertEqual(tick(at(2027, 1, 1, 0, 0)), at(2027, 1, 1, 0, 1).addingTimeInterval(0.05))
        XCTAssertEqual(tick(at(2026, 12, 31, 23, 57, 10), .classic), at(2027, 1, 1, 0, 0).addingTimeInterval(0.05))
    }

    func testUserTimesDailyAndYearly() {
        let pi = SpecialTime(hour: 15, minute: 14, text: "pi o'clock")
        let birthday = SpecialTime(hour: 12, minute: 0, month: 3, day: 14, text: "happy birthday")
        let times = [pi, birthday]
        XCTAssertEqual(text(at(2026, 9, 22, 15, 14), .spoken, times), "pi o'clock")
        XCTAssertEqual(text(at(2026, 9, 22, 15, 15), .spoken, times), "quarter past three")
        XCTAssertEqual(text(at(2026, 9, 22, 3, 14), .spoken, times), "quarter past three", "3:14 am is not 15:14")
        XCTAssertEqual(text(at(2027, 3, 14, 12, 0), .german, times), "happy birthday")
        XCTAssertEqual(text(at(2027, 3, 15, 12, 0), .german, times), "kurz nach zwölf")
    }

    func testUserTimeWinsOverNewYearAndEmptyTextIsIgnored() {
        let mine = SpecialTime(hour: 0, minute: 0, month: 1, day: 1, text: "2027!")
        XCTAssertEqual(text(at(2027, 1, 1, 0, 0), .spoken, [mine]), "2027!")
        let blank = SpecialTime(hour: 0, minute: 0, text: "")
        XCTAssertEqual(text(at(2027, 1, 1, 0, 0), .spoken, [blank]), "Happy New Year!")
        XCTAssertEqual(text(at(2027, 1, 2, 0, 0), .spoken, [blank]), "twelve o'clock")
    }

    func testLongTextIsCutToTheNotchLimit() {
        let long = SpecialTime(hour: 9, minute: 0, text: String(repeating: "x", count: 50))
        XCTAssertEqual(text(at(2026, 9, 22, 9, 0), .spoken, [long]).count, SpecialTime.maxLength)
    }

    @MainActor
    func testClockPersistsSpecialTimesAndWakesForThem() {
        let suite = "FuzzyBarTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        // Clock phrases in the current calendar, so build the date there too.
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 22, hour: 9, minute: 18))!
        let clock = Clock(dateProvider: { now }, defaults: defaults)
        XCTAssertEqual(clock.specialTimes, [])
        XCTAssertEqual(clock.timerFireDate, now.addingTimeInterval(5 * 60 + 0.05), "twenty past holds until 9:23")

        clock.specialTimes = [SpecialTime(hour: 9, minute: 21, text: "tea")]
        XCTAssertEqual(clock.timerFireDate, now.addingTimeInterval(3 * 60 + 0.05), "wakes at 9:21 for it")

        let reloaded = Clock(dateProvider: { now }, defaults: defaults)
        XCTAssertEqual(reloaded.specialTimes, clock.specialTimes)

        defaults.set(Data("not json".utf8), forKey: SpecialTimes.defaultsKey)
        XCTAssertEqual(Clock(dateProvider: { now }, defaults: defaults).specialTimes, [])
    }
}

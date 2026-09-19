import XCTest
@testable import FuzzyBar

/// Expectations ported from LittleFuzzyClock's tests/test_fuzzy_time.py,
/// with the phrase and hour halves joined the way the menubar shows them.
final class PersonalityTests: XCTestCase {
    private func p(_ h: Int, _ m: Int, _ personality: Personality) -> String {
        FuzzyTime.phrase(hour: h, minute: m, personality: personality)
    }

    func testSpokenIsTheDefaultAndUnchanged() {
        XCTAssertEqual(Personality.default, .spoken)
        XCTAssertEqual(p(20, 40, .spoken), FuzzyTime.phrase(hour: 20, minute: 40))
        XCTAssertEqual(p(9, 30, .spoken), "half past nine")
        XCTAssertEqual(p(11, 58, .spoken), "twelve o'clock")
    }

    func testHalfPastNineAcrossEveryPersonality() {
        XCTAssertEqual(p(9, 30, .classic), "half past nine am")
        XCTAssertEqual(p(9, 30, .shakespeare), "'tis half past nine of the clock")
        XCTAssertEqual(p(9, 30, .klingon), "half past Hut rep")
        XCTAssertEqual(p(9, 30, .belter), "half past nine bell, ya")
        XCTAssertEqual(p(9, 30, .german), "halb zehn")
        XCTAssertEqual(p(9, 30, .hal), "MIDPOINT, 0900 HOURS")
        XCTAssertEqual(p(9, 30, .cthulhu), "the half-hour, the ninth hour")
        XCTAssertEqual(p(9, 30, .latin), "media post hora IX a.m.")
    }

    func testClassic() {
        XCTAssertEqual(p(9, 0, .classic), "just after nine am")
        XCTAssertEqual(p(9, 45, .classic), "quarter to ten am")
        XCTAssertEqual(p(9, 57, .classic), "almost ten am")
        XCTAssertEqual(p(9, 59, .classic), "almost ten am")
        XCTAssertEqual(p(11, 58, .classic), "almost twelve pm")
        XCTAssertEqual(p(23, 58, .classic), "almost twelve am")
        XCTAssertEqual(p(0, 0, .classic), "just after twelve am")
        XCTAssertEqual(p(12, 0, .classic), "just after twelve pm")
        XCTAssertEqual(p(15, 30, .classic), "half past three pm")
        XCTAssertEqual(p(11, 45, .classic), "quarter to twelve pm")
    }

    func testShakespeare() {
        XCTAssertEqual(p(9, 0, .shakespeare), "'tis just past nine of the clock")
        XCTAssertEqual(p(9, 15, .shakespeare), "'tis a quarter past nine of the clock")
        XCTAssertEqual(p(9, 45, .shakespeare), "a quarter 'fore ten of the clock")
        XCTAssertEqual(p(9, 58, .shakespeare), "almost ten of the clock")
        XCTAssertEqual(p(23, 58, .shakespeare), "almost twelve of the clock")
    }

    func testKlingon() {
        XCTAssertEqual(p(9, 0, .klingon), "newly forged Hut rep")
        XCTAssertEqual(p(9, 45, .klingon), "quarter 'til wa'maH rep")
        XCTAssertEqual(p(9, 58, .klingon), "battle nears wa'maH rep")
        XCTAssertEqual(p(23, 58, .klingon), "battle nears wa'maH cha' rep")
    }

    func testBelter() {
        XCTAssertEqual(p(9, 0, .belter), "just past nine bell, ya")
        XCTAssertEqual(p(9, 5, .belter), "showxa pasa nine bell, ya")
        XCTAssertEqual(p(9, 45, .belter), "quarter to da ten bell, ya")
        XCTAssertEqual(p(9, 58, .belter), "almost, ke ten bell, ya")
        XCTAssertEqual(p(23, 58, .belter), "almost, ke twelve bell, ya")
    }

    func testGermanAdvancesHourAtTwentyFivePast() {
        XCTAssertEqual(p(9, 0, .german), "kurz nach neun")
        XCTAssertEqual(p(9, 5, .german), "fünf nach neun")
        XCTAssertEqual(p(9, 15, .german), "viertel nach neun")
        XCTAssertEqual(p(9, 22, .german), "zwanzig nach neun")
        XCTAssertEqual(p(9, 23, .german), "fünf vor halb zehn")
        XCTAssertEqual(p(9, 25, .german), "fünf vor halb zehn")
        XCTAssertEqual(p(9, 35, .german), "fünf nach halb zehn")
        XCTAssertEqual(p(9, 45, .german), "viertel vor zehn")
        XCTAssertEqual(p(9, 58, .german), "kurz vor zehn")
        XCTAssertEqual(p(11, 30, .german), "halb zwölf")
        XCTAssertEqual(p(0, 30, .german), "halb eins")
        XCTAssertEqual(p(23, 58, .german), "kurz vor zwölf")
    }

    func testHalUsesTwentyFourHourTime() {
        XCTAssertEqual(p(9, 0, .hal), "ON THE MARK, 0900 HOURS")
        XCTAssertEqual(p(9, 15, .hal), "T+15 MINUTES, 0900 HOURS")
        XCTAssertEqual(p(9, 35, .hal), "T-25 MINUTES, 1000 HOURS")
        XCTAssertEqual(p(9, 45, .hal), "T-15 MINUTES, 1000 HOURS")
        XCTAssertEqual(p(9, 58, .hal), "IMMINENT, 1000 HOURS")
        XCTAssertEqual(p(21, 0, .hal), "ON THE MARK, 2100 HOURS")
        XCTAssertEqual(p(15, 30, .hal), "MIDPOINT, 1500 HOURS")
        XCTAssertEqual(p(12, 0, .hal), "ON THE MARK, 1200 HOURS")
        XCTAssertEqual(p(23, 58, .hal), "IMMINENT, 0000 HOURS")
        XCTAssertEqual(p(0, 0, .hal), "ON THE MARK, 0000 HOURS")
    }

    func testCthulhu() {
        XCTAssertEqual(p(9, 0, .cthulhu), "newly woken, the ninth hour")
        XCTAssertEqual(p(9, 45, .cthulhu), "quarter 'fore, the tenth hour")
        XCTAssertEqual(p(9, 58, .cthulhu), "the stars are right, the tenth hour")
        XCTAssertEqual(p(10, 45, .cthulhu), "quarter 'fore, the eleventh hour")
        XCTAssertEqual(p(23, 58, .cthulhu), "the stars are right, the twelfth hour")
        XCTAssertEqual(p(0, 30, .cthulhu), "the half-hour, the twelfth hour")
    }

    func testLatin() {
        XCTAssertEqual(p(9, 0, .latin), "modo post hora IX a.m.")
        XCTAssertEqual(p(9, 15, .latin), "quadrans post hora IX a.m.")
        XCTAssertEqual(p(9, 45, .latin), "quadrans ante hora X a.m.")
        XCTAssertEqual(p(9, 58, .latin), "fere hora X a.m.")
        XCTAssertEqual(p(15, 30, .latin), "media post hora III p.m.")
        XCTAssertEqual(p(23, 58, .latin), "fere hora XII a.m.")
    }

    /// Minutes 57-59 must name the *next* hour in every personality; the
    /// slot cap at 11 is what keeps them from wrapping to "just after".
    func testAlmostNextHourNeverWraps() {
        for personality in Personality.allCases where personality != .spoken {
            let slots = personality.slotPhrases!
            for hour in 0..<24 {
                for minute in 57...59 {
                    let text = p(hour, minute, personality)
                    XCTAssertTrue(text.hasPrefix(slots[11]), "\(personality) \(hour):\(minute) -> \(text)")
                    XCTAssertTrue(text.hasSuffix(personality.hourText(displayHour: (hour + 1) % 24)),
                                  "\(personality) \(hour):\(minute) -> \(text)")
                }
            }
        }
    }

    func testEveryMinuteUsesKnownVocabulary() {
        for personality in Personality.allCases where personality != .spoken {
            let slots = personality.slotPhrases!
            XCTAssertEqual(slots.count, 12, "\(personality)")
            XCTAssertTrue((1...11).contains(personality.hourAdvanceSlot), "\(personality)")
            for hour in 0..<24 {
                for minute in 0..<60 {
                    let text = p(hour, minute, personality)
                    XCTAssertTrue(slots.contains { text.hasPrefix($0 + personality.joiner) },
                                  "\(personality) \(hour):\(minute) -> \(text)")
                }
            }
        }
    }

    @MainActor
    func testClockPersistsPersonalityAndRephrases() {
        let suite = "FuzzyBarTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2026, month: 9, day: 18, hour: 9, minute: 30))!

        let clock = Clock(dateProvider: { date }, defaults: defaults)
        XCTAssertEqual(clock.personality, .spoken)
        clock.personality = .hal
        XCTAssertEqual(defaults.string(forKey: Personality.defaultsKey), "hal")
        XCTAssertEqual(clock.fuzzy, FuzzyTime.phrase(for: date, personality: .hal))

        let reloaded = Clock(dateProvider: { date }, defaults: defaults)
        XCTAssertEqual(reloaded.personality, .hal)

        defaults.set("not-a-personality", forKey: Personality.defaultsKey)
        XCTAssertEqual(Clock(dateProvider: { date }, defaults: defaults).personality, .spoken)
    }

    /// The ported personalities all change phrase on the same minutes, and the
    /// ticker must follow the active one: spoken flips to "ten o'clock" at
    /// 9:58, the others hold "almost ten" until 10:00.
    @MainActor
    func testTickFollowsTheActivePersonality() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        func at(_ minute: Int) -> Date {
            cal.date(from: DateComponents(year: 2026, month: 9, day: 18, hour: 9, minute: minute))!
        }
        let ported = Personality.allCases.filter { $0 != .spoken }
        for minute in [0, 2, 3, 22, 23, 27, 28, 52, 57] {
            let expected = Clock.nextTick(after: at(minute), popoverVisible: false, calendar: cal, personality: .classic)
            for personality in ported {
                XCTAssertEqual(Clock.nextTick(after: at(minute), popoverVisible: false, calendar: cal, personality: personality),
                               expected, "\(personality) at 9:\(minute)")
            }
        }
        XCTAssertEqual(Clock.nextTick(after: at(57), popoverVisible: false, calendar: cal, personality: .spoken),
                       at(58).addingTimeInterval(0.05))
        XCTAssertEqual(Clock.nextTick(after: at(57), popoverVisible: false, calendar: cal, personality: .classic),
                       at(60).addingTimeInterval(0.05))
    }
}

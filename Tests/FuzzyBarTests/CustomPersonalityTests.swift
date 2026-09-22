import XCTest
@testable import FuzzyBar

final class CustomPersonalityTests: XCTestCase {
    private func decode(_ json: String) throws -> CustomPersonality {
        try CustomPersonality.decode(Data(json.utf8))
    }

    private func assertFails(_ json: String, _ expected: CustomPersonality.ImportError,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try decode(json), file: file, line: line) {
            XCTAssertEqual($0 as? CustomPersonality.ImportError, expected, file: file, line: line)
        }
    }

    private let twelve = (1...12).map { "\"s\($0)\"" }.joined(separator: ",")
    private let hours = (0..<12).map { "\"h\($0)\"" }.joined(separator: ",")

    private var pirateURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../Examples/Pirate.fuzzybar")
    }

    func testThePirateExampleImports() throws {
        let pirate = try CustomPersonality.decode(Data(contentsOf: pirateURL))
        XCTAssertEqual(pirate.name, "Pirate")
        XCTAssertEqual(pirate.phrase(hour: 20, minute: 40), "twenty 'fore nine, arr")
        XCTAssertEqual(pirate.phrase(hour: 23, minute: 58), "nigh on twelve, arr")
        XCTAssertEqual(pirate.phrase(hour: 0, minute: 1), "smack on twelve, arr")
        XCTAssertLessThanOrEqual(pirate.longestReading.count, SpecialTime.maxLength, pirate.longestReading)
    }

    /// Saving any slot-table personality as a template and reading it back
    /// gives the same reading at every minute, so the format can say
    /// everything the built-in ones do.
    func testEveryTemplateRoundTripsExactly() throws {
        for personality in Personality.allCases {
            guard let template = personality.template else {
                XCTAssertNil(personality.slotPhrases, "\(personality) has a slot table but no template")
                continue
            }
            let read = try CustomPersonality.decode(template.encoded())
            for hour in 0..<24 {
                for minute in 0..<60 {
                    XCTAssertEqual(read.phrase(hour: hour, minute: minute),
                                   FuzzyTime.phrase(hour: hour, minute: minute, personality: personality),
                                   "\(personality) \(hour):\(minute)")
                }
            }
        }
        XCTAssertNil(Personality.spoken.template)
        XCTAssertNil(Personality.vague.template)
        // am/pm personalities need all 24 hours; the rest fold to 12.
        XCTAssertEqual(Personality.classic.template?.hours.count, 24)
        XCTAssertEqual(Personality.german.template?.hours.count, 12)
    }

    /// Only the app bundle declares the type, so this runs under the Xcode
    /// project's hosted tests and skips under SwiftPM.
    func testTheFileTypeIsDeclared() throws {
        try XCTSkipUnless(Bundle.main.bundleIdentifier == "dev.plumpbug.fuzzybar", "needs the app's Info.plist")
        XCTAssertEqual(CustomPersonality.contentType.preferredFilenameExtension, "fuzzybar")
        XCTAssertTrue(CustomPersonality.contentType.conforms(to: .json))
    }

    func testDefaultsForOptionalFields() throws {
        let p = try decode(#"{"name": "Min", "slots": [\#(twelve)], "hours": [\#(hours)]}"#)
        XCTAssertEqual(p.format, "{phrase} {hour}")
        XCTAssertEqual(p.nextHourFrom, 7)
        XCTAssertEqual(p.phrase(hour: 9, minute: 35), "s8 h10")
        XCTAssertEqual(p.phrase(hour: 9, minute: 30), "s7 h9")
    }

    func testTwentyFourHoursAndHourFirstFormats() throws {
        let h24 = (0..<24).map { "\"H\($0)\"" }.joined(separator: ",")
        let p = try decode(#"{"name": "X", "format": "{hour}: {phrase}", "slots": [\#(twelve)], "hours": [\#(h24)], "nextHourFrom": 5}"#)
        XCTAssertEqual(p.phrase(hour: 21, minute: 20), "H21: s5")
        XCTAssertEqual(p.phrase(hour: 21, minute: 25), "H22: s6")
        XCTAssertEqual(p.phrase(hour: 23, minute: 59), "H0: s12")
    }

    func testAPhraseContainingAPlaceholderIsLeftAlone() throws {
        let slots = (["{hour} o'clock"] + (2...12).map { "s\($0)" }).map { "\"\($0)\"" }.joined(separator: ",")
        let p = try decode(#"{"name": "X", "slots": [\#(slots)], "hours": [\#(hours)]}"#)
        XCTAssertEqual(p.phrase(hour: 3, minute: 0), "{hour} o'clock h3")
    }

    func testErrorsNameTheProblem() {
        assertFails("not json", .notJSON)
        assertFails(#"{"version": 2, "name": "X"}"#, .newerVersion(2))
        assertFails(#"{"slots": [\#(twelve)], "hours": [\#(hours)]}"#, .missing("name"))
        assertFails(#"{"name": "  ", "slots": [\#(twelve)], "hours": [\#(hours)]}"#, .missing("name"))
        assertFails(#"{"name": "X", "hours": [\#(hours)]}"#, .missing("slots"))
        assertFails(#"{"name": "X", "slots": ["a"], "hours": [\#(hours)]}"#,
                    .wrongCount("slots", expected: "12 phrases", found: 1))
        assertFails(#"{"name": "X", "slots": [\#(twelve)]}"#, .missing("hours"))
        assertFails(#"{"name": "X", "slots": [\#(twelve)], "hours": ["a", "b"]}"#,
                    .wrongCount("hours", expected: "12 or 24 names", found: 2))
        let blank = (["s1", " "] + (3...12).map { "s\($0)" }).map { "\"\($0)\"" }.joined(separator: ",")
        assertFails(#"{"name": "X", "slots": [\#(blank)], "hours": [\#(hours)]}"#, .emptyEntry("slots", index: 1))
        assertFails(#"{"name": "X", "format": "{phrase}", "slots": [\#(twelve)], "hours": [\#(hours)]}"#,
                    .formatNeedsPlaceholders)
        assertFails(#"{"name": "X", "slots": [\#(twelve)], "hours": [\#(hours)], "nextHourFrom": 12}"#,
                    .nextHourOutOfRange(12))
        // Escaped newlines are blank to the eye, and the menubar has one line.
        assertFails(#"{"name": "\n", "slots": [\#(twelve)], "hours": [\#(hours)]}"#, .missing("name"))
        let newlineSlot = (["s1", "\\n"] + (3...12).map { "s\($0)" }).map { "\"\($0)\"" }.joined(separator: ",")
        assertFails(#"{"name": "X", "slots": [\#(newlineSlot)], "hours": [\#(hours)]}"#, .emptyEntry("slots", index: 1))
        let brokenHour = (["h0", "h1", "one\\ntwo"] + (3..<12).map { "h\($0)" }).map { "\"\($0)\"" }.joined(separator: ",")
        assertFails(#"{"name": "X", "slots": [\#(twelve)], "hours": [\#(brokenHour)]}"#, .lineBreak("hours", index: 2))
        assertFails(#"{"name": "X", "format": "{phrase}\n{hour}", "slots": [\#(twelve)], "hours": [\#(hours)]}"#,
                    .lineBreak("format", index: nil))
        assertFails(#"{"name": "Pi\rrate", "slots": [\#(twelve)], "hours": [\#(hours)]}"#, .lineBreak("name", index: nil))
        XCTAssertEqual(CustomPersonality.ImportError.wrongCount("slots", expected: "12 phrases", found: 11).errorDescription,
                       "\"slots\" needs 12 phrases, this file has 11.")
    }

    @MainActor
    func testImportSwitchesReplacesByNameAndRemoveFallsBack() throws {
        let suite = "FuzzyBarTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 22, hour: 20, minute: 40))!
        let clock = Clock(dateProvider: { now }, defaults: defaults)
        clock.personality = .german

        let pirate = try CustomPersonality.decode(Data(contentsOf: pirateURL))
        XCTAssertFalse(clock.importPersonality(pirate))
        XCTAssertEqual(clock.fuzzy, "twenty 'fore nine, arr")
        let id = try XCTUnwrap(clock.customPersonalityID)

        // Same name, different case: an update, not a second entry.
        var edited = pirate
        edited.name = "PIRATE"
        edited.format = "{phrase} {hour}, yarr"
        XCTAssertTrue(clock.importPersonality(edited))
        XCTAssertEqual(clock.customPersonalities.count, 1)
        XCTAssertEqual(clock.customPersonalityID, id)
        XCTAssertEqual(clock.fuzzy, "twenty 'fore nine, yarr")

        // Survives a relaunch.
        let reloaded = Clock(dateProvider: { now }, defaults: defaults)
        XCTAssertEqual(reloaded.customPersonalityID, id)
        XCTAssertEqual(reloaded.fuzzy, "twenty 'fore nine, yarr")

        // Removing the active one goes back to the built-in it replaced.
        clock.removePersonality(id: id)
        XCTAssertNil(clock.customPersonalityID)
        XCTAssertEqual(clock.fuzzy, "zwanzig vor neun")
        XCTAssertNil(Clock(dateProvider: { now }, defaults: defaults).customPersonalityID)
    }

    @MainActor
    func testAMissingActiveCustomFallsBackAtLaunch() {
        let suite = "FuzzyBarTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(UUID().uuidString, forKey: Clock.customActiveKey)
        let clock = Clock(dateProvider: { Date() }, defaults: defaults)
        XCTAssertNil(clock.customPersonalityID)
        XCTAssertNil(defaults.string(forKey: Clock.customActiveKey))
    }

    /// Special times win over everything, a custom personality included,
    /// and the ticker follows the custom one's boundaries.
    @MainActor
    func testSpecialTimesWinAndTheTickerFollowsTheCustomOne() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        func at(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ m: Int) -> Date {
            cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: m))!
        }
        let pirate = try CustomPersonality.decode(Data(contentsOf: pirateURL))
        let tea = SpecialTime(hour: 16, minute: 0, text: "tea")
        func text(_ date: Date) -> String {
            Clock.text(for: date, calendar: cal, personality: .spoken, custom: pirate, specialTimes: [tea])
        }
        XCTAssertEqual(text(at(2026, 9, 22, 16, 0)), "tea")
        XCTAssertEqual(text(at(2027, 1, 1, 0, 0)), "Happy New Year!")
        XCTAssertEqual(text(at(2026, 9, 22, 16, 1)), "smack on four, arr")

        // Pirate holds "nigh on" to :59 like the ported ones; Spoken would flip at :58.
        XCTAssertEqual(Clock.nextTick(after: at(2026, 9, 22, 9, 57), popoverVisible: false, calendar: cal,
                                      personality: .spoken, custom: pirate),
                       at(2026, 9, 22, 10, 0).addingTimeInterval(0.05))
    }
}

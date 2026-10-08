import XCTest

extension XCTestCase {
    /// A UserDefaults suite of the test's own, removed when the test ends.
    func scratchDefaults() -> UserDefaults {
        let suite = "FuzzyBarTests.\(UUID().uuidString)"
        addTeardownBlock { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        return UserDefaults(suiteName: suite)!
    }
}

/// A Gregorian calendar in `zone`, so a test's dates don't depend on the Mac's.
func gregorian(_ zone: String = "UTC") -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: zone)!
    return cal
}

func iso(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

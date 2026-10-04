import XCTest

extension XCTestCase {
    /// A UserDefaults suite of the test's own, removed when the test ends.
    func scratchDefaults() -> UserDefaults {
        let suite = "FuzzyBarTests.\(UUID().uuidString)"
        addTeardownBlock { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        return UserDefaults(suiteName: suite)!
    }
}

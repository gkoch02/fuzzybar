import Foundation

/// A minute the user wants to read differently: "pi o'clock" at 3:14, or a
/// birthday at noon. It replaces the personality's phrase for that one
/// minute and then the ordinary phrase comes back.
struct SpecialTime: Codable, Equatable, Identifiable {
    var id = UUID()
    var hour: Int
    var minute: Int
    /// Both set for one day a year; both `nil` for every day.
    var month: Int?
    var day: Int?
    var text: String

    /// Longer than this and a notched MacBook hides it behind the notch.
    static let maxLength = 30

    func matches(_ c: DateComponents) -> Bool {
        guard c.hour == hour, c.minute == minute else { return false }
        guard let month, let day else { return true }
        return c.month == month && c.day == day
    }
}

enum SpecialTimes {
    static let defaultsKey = "specialTimes"

    /// The one built in: the first minute of the year, in any personality.
    static let newYear = SpecialTime(hour: 0, minute: 0, month: 1, day: 1, text: "Happy New Year!")

    /// What to show instead of the phrase at `date`, if anything. The
    /// user's own times come first, so one set for New Year's midnight wins.
    static func text(for date: Date, calendar: Calendar = .current, userTimes: [SpecialTime]) -> String? {
        let c = calendar.dateComponents([.month, .day, .hour, .minute], from: date)
        let match = userTimes.first { $0.matches(c) && !$0.text.isEmpty } ?? (newYear.matches(c) ? newYear : nil)
        return match.map { String($0.text.prefix(SpecialTime.maxLength)) }
    }

    static func load(from defaults: UserDefaults) -> [SpecialTime] {
        guard let data = defaults.data(forKey: defaultsKey) else { return [] }
        return (try? JSONDecoder().decode([SpecialTime].self, from: data)) ?? []
    }

    static func save(_ times: [SpecialTime], to defaults: UserDefaults) {
        defaults.set(try? JSONEncoder().encode(times), forKey: defaultsKey)
    }
}

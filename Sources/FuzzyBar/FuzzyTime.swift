import Foundation

/// Converts a clock time into a fuzzy phrase like "twenty to nine".
/// Minutes are rounded to the nearest five (37 -> 35, 38 -> 40).
enum FuzzyTime {
    private static let hourWords = [
        "twelve", "one", "two", "three", "four", "five",
        "six", "seven", "eight", "nine", "ten", "eleven",
    ]

    static func phrase(hour: Int, minute: Int) -> String {
        var h = hour
        var slot = Int((Double(minute) / 5.0).rounded())  // 0...12
        if slot == 12 { slot = 0; h += 1 }

        // Anything past the half hour references the *next* hour.
        let hourWord = hourWords[h % 12]
        let nextHourWord = hourWords[(h + 1) % 12]

        switch slot {
        case 0: return "\(hourWord) o'clock"
        case 1: return "five past \(hourWord)"
        case 2: return "ten past \(hourWord)"
        case 3: return "quarter past \(hourWord)"
        case 4: return "twenty past \(hourWord)"
        case 5: return "twenty-five past \(hourWord)"
        case 6: return "half past \(hourWord)"
        case 7: return "twenty-five to \(nextHourWord)"
        case 8: return "twenty to \(nextHourWord)"
        case 9: return "quarter to \(nextHourWord)"
        case 10: return "ten to \(nextHourWord)"
        case 11: return "five to \(nextHourWord)"
        default: return "\(hourWord) o'clock"
        }
    }

    static func phrase(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return phrase(hour: c.hour ?? 0, minute: c.minute ?? 0)
    }
}

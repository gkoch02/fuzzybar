import Foundation

/// Converts a clock time into a fuzzy phrase like "twenty to nine".
/// Minutes are rounded to the nearest five (37 -> 35, 38 -> 40).
/// The default "spoken" personality is FuzzyBar's own; the rest come from
/// LittleFuzzyClock and share its twelve-slot table (see `Personality`).
enum FuzzyTime {
    private static let hourWords = [
        "twelve", "one", "two", "three", "four", "five",
        "six", "seven", "eight", "nine", "ten", "eleven",
    ]

    static func phrase(hour: Int, minute: Int, personality: Personality = .default) -> String {
        if personality == .vague { return vaguePhrase(hour: hour, minute: minute) }
        guard let slots = personality.slotPhrases else { return spokenPhrase(hour: hour, minute: minute) }
        // Cap at 11 so minutes 57-59 read "almost [next hour]" rather than
        // wrapping back to "just after [current hour]".
        let slot = min(Int((Double(minute) / 5.0).rounded()), 11)
        let displayHour = slot < personality.hourAdvanceSlot ? hour : (hour + 1) % 24
        return slots[slot] + personality.joiner + personality.hourText(displayHour: displayHour)
    }

    /// No rounding: the parts of the day start on the exact minute.
    private static func vaguePhrase(hour: Int, minute: Int) -> String {
        let minuteOfDay = hour * 60 + minute
        return Personality.vagueParts.last { $0.start <= minuteOfDay }!.phrase
    }

    private static func spokenPhrase(hour: Int, minute: Int) -> String {
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

    static func phrase(for date: Date, calendar: Calendar = .current, personality: Personality = .default) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return phrase(hour: c.hour ?? 0, minute: c.minute ?? 0, personality: personality)
    }
}

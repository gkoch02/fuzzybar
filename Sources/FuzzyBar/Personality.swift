import Foundation

/// The phrasing styles ported from LittleFuzzyClock, plus FuzzyBar's own
/// spoken-English default. LittleFuzzyClock renders the phrase and the hour
/// on two lines of an e-ink panel; the menubar gets one line, so each
/// personality also says how to join the two halves.
///
/// Four of them were named after franchises (Klingon, Belter, HAL 9000,
/// Cthulhu) until the App Store submission. HAL 9000 and Cthulhu only ever
/// borrowed a label, so they kept their tables and became Mission Control
/// and Eldritch. Klingon and Belter went further than a name: their phrases
/// were tlhIngan Hol numerals and Lang Belta particles, the languages
/// themselves rather than a reference to them. Both are withdrawn rather
/// than rewritten, so the app ships seven.
enum Personality: String, CaseIterable, Identifiable {
    case spoken
    case classic
    case shakespeare
    case german
    case missionControl
    case eldritch
    case latin

    static let `default`: Personality = .spoken
    static let defaultsKey = "personality"

    /// Raw values written by builds from before the rename. A preference
    /// file is the user's choice, not ours to drop, so map it forward.
    /// "klingon" and "belter" are deliberately absent: those two were
    /// withdrawn rather than renamed, and nothing survives to map them to,
    /// so they fall back to the default the way an unknown value does.
    private static let renamed: [String: Personality] = [
        "hal": .missionControl,
        "cthulhu": .eldritch,
    ]

    /// Reads a stored `defaultsKey` string, migrating a pre-rename value.
    /// `nil` for a withdrawn one and for anything that was never a
    /// personality; the caller supplies the default.
    static func stored(_ raw: String) -> Personality? {
        Personality(rawValue: raw) ?? renamed[raw]
    }

    var id: String { rawValue }

    /// Name shown in Preferences.
    var title: String {
        switch self {
        case .spoken: return "Spoken"
        case .classic: return "Classic"
        case .shakespeare: return "Shakespeare"
        case .german: return "German"
        case .missionControl: return "Mission Control"
        case .eldritch: return "Eldritch"
        case .latin: return "Latin"
        }
    }

    /// One-line description for the picker.
    var note: String {
        switch self {
        case .spoken: return "The way you'd say it out loud."
        case .classic: return "Plain English with am and pm."
        case .shakespeare: return "Archaic English; no am or pm, that's anachronistic."
        case .german: return "Standard High German; \"halb\" anchors on the next hour."
        case .missionControl: return "Mission-control patter in 24-hour time."
        case .eldritch: return "Cosmic dread; climaxes with \"the stars are right\"."
        case .latin: return "Roman-numeral hours and real Latin prepositions."
        }
    }

    /// The twelve five-minute slots, index 0 = on the hour, 11 = "almost".
    /// `nil` for the spoken personality, which has its own thirteen-slot logic.
    var slotPhrases: [String]? {
        switch self {
        case .spoken:
            return nil
        case .classic:
            return ["just after", "a little past", "ten past", "quarter past", "twenty past",
                    "twenty-five past", "half past", "twenty-five to", "twenty to", "quarter to",
                    "ten to", "almost"]
        case .shakespeare:
            return ["'tis just past", "a moment past", "ten past", "'tis a quarter past", "twenty past",
                    "twenty-five past", "'tis half past", "twenty-five 'fore", "twenty 'fore",
                    "a quarter 'fore", "ten 'fore", "almost"]
        case .german:
            return ["kurz nach", "fünf nach", "zehn nach", "viertel nach", "zwanzig nach",
                    "fünf vor halb", "halb", "fünf nach halb", "zwanzig vor", "viertel vor",
                    "zehn vor", "kurz vor"]
        case .missionControl:
            return ["ON THE MARK", "T+5 MINUTES", "T+10 MINUTES", "T+15 MINUTES", "T+20 MINUTES",
                    "T+25 MINUTES", "MIDPOINT", "T-25 MINUTES", "T-20 MINUTES", "T-15 MINUTES",
                    "T-10 MINUTES", "IMMINENT"]
        case .eldritch:
            return ["newly woken", "moments past", "ten past", "quarter past", "twenty past",
                    "twenty-five past", "the half-hour", "twenty-five 'fore", "twenty 'fore",
                    "quarter 'fore", "ten 'fore", "the stars are right"]
        case .latin:
            return ["modo post", "quinque post", "decem post", "quadrans post", "viginti post",
                    "viginti quinque post", "media post", "viginti quinque ante", "viginti ante",
                    "quadrans ante", "decem ante", "fere"]
        }
    }

    /// The slot at which the displayed hour flips to the next one. German's
    /// "fünf vor halb zehn" already names the next hour at 25 past, so it
    /// flips at 5; everyone else at 7 (twenty-five to). Must stay in 1...11
    /// so the "almost" slot always names the next hour.
    var hourAdvanceSlot: Int { self == .german ? 5 : 7 }

    /// Joiner between the phrase and the hour on the single menubar line.
    var joiner: String {
        switch self {
        case .missionControl, .eldritch: return ", "
        default: return " "
        }
    }

    private static let englishHours = [
        "twelve", "one", "two", "three", "four", "five",
        "six", "seven", "eight", "nine", "ten", "eleven",
    ]
    private static let germanHours = [
        "zwölf", "eins", "zwei", "drei", "vier", "fünf",
        "sechs", "sieben", "acht", "neun", "zehn", "elf",
    ]
    private static let ordinalHours = [
        "twelfth", "first", "second", "third", "fourth", "fifth",
        "sixth", "seventh", "eighth", "ninth", "tenth", "eleventh",
    ]
    private static let romanHours = [
        "XII", "I", "II", "III", "IV", "V",
        "VI", "VII", "VIII", "IX", "X", "XI",
    ]

    /// Renders the hour half for a 24-hour display hour (0...23).
    func hourText(displayHour: Int) -> String {
        let h24 = ((displayHour % 24) + 24) % 24
        let index = h24 % 12  // 0 = twelve
        let isPM = h24 >= 12
        switch self {
        case .spoken, .classic:
            return "\(Self.englishHours[index]) \(isPM ? "pm" : "am")"
        case .shakespeare:
            return "\(Self.englishHours[index]) of the clock"
        case .german:
            return Self.germanHours[index]
        case .missionControl:
            return String(format: "%02d00 HOURS", h24)
        case .eldritch:
            return "the \(Self.ordinalHours[index]) hour"
        case .latin:
            return "hora \(Self.romanHours[index]) \(isPM ? "p.m." : "a.m.")"
        }
    }
}

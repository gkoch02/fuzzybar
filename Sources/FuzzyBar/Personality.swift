import Foundation

/// The phrasing styles ported from LittleFuzzyClock, plus FuzzyBar's own
/// spoken-English default. LittleFuzzyClock renders the phrase and the hour
/// on two lines of an e-ink panel; the menubar gets one line, so each
/// personality also says how to join the two halves.
enum Personality: String, CaseIterable, Identifiable {
    case spoken
    case classic
    case shakespeare
    case klingon
    case belter
    case german
    case hal
    case cthulhu
    case latin

    static let `default`: Personality = .spoken
    static let defaultsKey = "personality"

    var id: String { rawValue }

    /// Name shown in Preferences.
    var title: String {
        switch self {
        case .spoken: return "Spoken"
        case .classic: return "Classic"
        case .shakespeare: return "Shakespeare"
        case .klingon: return "Klingon"
        case .belter: return "Belter"
        case .german: return "German"
        case .hal: return "HAL 9000"
        case .cthulhu: return "Cthulhu"
        case .latin: return "Latin"
        }
    }

    /// One-line description for the picker.
    var note: String {
        switch self {
        case .spoken: return "The way you'd say it out loud."
        case .classic: return "Plain English with am and pm."
        case .shakespeare: return "Archaic English; no am or pm, that's anachronistic."
        case .klingon: return "Real tlhIngan Hol numerals; \"rep\" is Klingon for hour."
        case .belter: return "Lang Belta creole from The Expanse; nautical bells."
        case .german: return "Standard High German; \"halb\" anchors on the next hour."
        case .hal: return "Mission-control patter in 24-hour time."
        case .cthulhu: return "Lovecraftian dread; climaxes with \"the stars are right\"."
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
        case .klingon:
            return ["newly forged", "moments past", "ten past", "quarter past", "twenty past",
                    "twenty-five past", "half past", "twenty-five 'til", "twenty 'til", "quarter 'til",
                    "ten 'til", "battle nears"]
        case .belter:
            return ["just past", "showxa pasa", "ten past", "quarter past", "twenty past",
                    "twenty-five past", "half past", "twenty-five to da", "twenty to da", "quarter to da",
                    "ten to da", "almost, ke"]
        case .german:
            return ["kurz nach", "fünf nach", "zehn nach", "viertel nach", "zwanzig nach",
                    "fünf vor halb", "halb", "fünf nach halb", "zwanzig vor", "viertel vor",
                    "zehn vor", "kurz vor"]
        case .hal:
            return ["ON THE MARK", "T+5 MINUTES", "T+10 MINUTES", "T+15 MINUTES", "T+20 MINUTES",
                    "T+25 MINUTES", "MIDPOINT", "T-25 MINUTES", "T-20 MINUTES", "T-15 MINUTES",
                    "T-10 MINUTES", "IMMINENT"]
        case .cthulhu:
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
        case .hal, .cthulhu: return ", "
        default: return " "
        }
    }

    private static let englishHours = [
        "twelve", "one", "two", "three", "four", "five",
        "six", "seven", "eight", "nine", "ten", "eleven",
    ]
    private static let klingonHours = [
        "wa'maH cha'", "wa'", "cha'", "wej", "loS", "vagh",
        "jav", "Soch", "chorgh", "Hut", "wa'maH", "wa'maH wa'",
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
        case .klingon:
            return "\(Self.klingonHours[index]) rep"
        case .belter:
            return "\(Self.englishHours[index]) bell, ya"
        case .german:
            return Self.germanHours[index]
        case .hal:
            return String(format: "%02d00 HOURS", h24)
        case .cthulhu:
            return "the \(Self.ordinalHours[index]) hour"
        case .latin:
            return "hora \(Self.romanHours[index]) \(isPM ? "p.m." : "a.m.")"
        }
    }
}

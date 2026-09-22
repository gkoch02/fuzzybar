import Foundation
import UniformTypeIdentifiers

/// A personality from a file the user wrote: the same twelve-slot engine the
/// ported personalities use, with every word supplied. FuzzyBar ships no
/// custom personalities, and nothing in one comes from us.
struct CustomPersonality: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    /// Contains `{phrase}` and `{hour}`, e.g. "{phrase} {hour}".
    var format: String
    /// Twelve five-minute slots: 0 is on the hour, 11 is "almost".
    var slots: [String]
    /// Twelve hour names (twelve, one, ... eleven), or twenty-four
    /// (midnight through 11 pm) where am and pm read differently.
    var hours: [String]
    /// The slot from which the hour named is the next one: 7 ("twenty-five
    /// to") for English, 5 for German's "fünf vor halb".
    var nextHourFrom: Int

    static let fileExtension = "fuzzybar"
    static let contentType = UTType(exportedAs: "dev.plumpbug.fuzzybar.personality", conformingTo: .json)
    /// The file format this build reads and writes.
    static let formatVersion = 1

    func phrase(hour: Int, minute: Int) -> String {
        let slot = min(Int((Double(minute) / 5.0).rounded()), 11)
        let h24 = ((slot < nextHourFrom ? hour : hour + 1) % 24 + 24) % 24
        let hourText = hours.count == 24 ? hours[h24] : hours[h24 % 12]
        // One pass, so a phrase that happens to contain "{hour}" stays as written.
        return format.components(separatedBy: "{phrase}")
            .map { $0.replacingOccurrences(of: "{hour}", with: hourText) }
            .joined(separator: slots[slot])
    }

    /// The longest thing it can put in the menubar, for the notch warning.
    var longestReading: String {
        (0..<24).flatMap { h in stride(from: 0, to: 60, by: 5).map { phrase(hour: h, minute: $0) } }
            .max { $0.count < $1.count } ?? ""
    }
}

// MARK: - Files

extension CustomPersonality {
    /// What's in a .fuzzybar file. Separate from the stored model so the file
    /// has no id, and optional fields can be left out.
    private struct File: Codable {
        var version: Int?
        var name: String?
        var format: String?
        var slots: [String]?
        var hours: [String]?
        var nextHourFrom: Int?
    }

    enum ImportError: LocalizedError, Equatable {
        case notJSON
        case newerVersion(Int)
        case missing(String)
        case wrongCount(String, expected: String, found: Int)
        case emptyEntry(String, index: Int)
        case formatNeedsPlaceholders
        case nextHourOutOfRange(Int)

        var errorDescription: String? {
            switch self {
            case .notJSON:
                return "That file isn't a FuzzyBar personality: it needs to be JSON, like a saved template."
            case let .newerVersion(v):
                return "That file is format version \(v), made for a newer FuzzyBar."
            case let .missing(key):
                return "The file needs \"\(key)\"."
            case let .wrongCount(key, expected, found):
                return "\"\(key)\" needs \(expected), this file has \(found)."
            case let .emptyEntry(key, index):
                return "Entry \(index + 1) of \"\(key)\" is empty."
            case .formatNeedsPlaceholders:
                return "\"format\" needs both {phrase} and {hour}."
            case let .nextHourOutOfRange(n):
                return "\"nextHourFrom\" must be between 1 and 11, not \(n)."
            }
        }
    }

    /// Reads and checks a file. Everything wrong with it is reported by name,
    /// since the person reading the message is editing JSON by hand.
    static func decode(_ data: Data) throws -> CustomPersonality {
        let file: File
        do { file = try JSONDecoder().decode(File.self, from: data) } catch { throw ImportError.notJSON }
        if let v = file.version, v > formatVersion { throw ImportError.newerVersion(v) }
        guard let name = file.name?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            throw ImportError.missing("name")
        }
        guard let slots = file.slots else { throw ImportError.missing("slots") }
        guard slots.count == 12 else { throw ImportError.wrongCount("slots", expected: "12 phrases", found: slots.count) }
        guard let hours = file.hours else { throw ImportError.missing("hours") }
        guard hours.count == 12 || hours.count == 24 else {
            throw ImportError.wrongCount("hours", expected: "12 or 24 names", found: hours.count)
        }
        for (key, list) in [("slots", slots), ("hours", hours)] {
            if let i = list.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                throw ImportError.emptyEntry(key, index: i)
            }
        }
        let format = file.format ?? "{phrase} {hour}"
        guard format.contains("{phrase}"), format.contains("{hour}") else { throw ImportError.formatNeedsPlaceholders }
        let nextHourFrom = file.nextHourFrom ?? 7
        guard (1...11).contains(nextHourFrom) else { throw ImportError.nextHourOutOfRange(nextHourFrom) }
        return CustomPersonality(name: name, format: format, slots: slots, hours: hours, nextHourFrom: nextHourFrom)
    }

    /// Pretty-printed with the keys in reading order, so a saved template is
    /// something a person can edit.
    func encoded() -> Data {
        func quoted(_ s: String) -> String {
            String(data: try! JSONEncoder().encode(s), encoding: .utf8)!
        }
        func list(_ items: [String]) -> String {
            "[\n" + items.map { "    " + quoted($0) }.joined(separator: ",\n") + "\n  ]"
        }
        let body = """
        {
          "version": \(Self.formatVersion),
          "name": \(quoted(name)),
          "format": \(quoted(format)),
          "slots": \(list(slots)),
          "hours": \(list(hours)),
          "nextHourFrom": \(nextHourFrom)
        }

        """
        return Data(body.utf8)
    }
}

// MARK: - Templates

extension Personality {
    /// This personality written out as a custom one, for Save as Template.
    /// Spoken and Vague don't use the twelve-slot table, so they have none.
    var template: CustomPersonality? {
        guard let slots = slotPhrases else { return nil }
        let hours = (0..<24).map { hourText(displayHour: $0) }
        let halves = hours[0..<12].elementsEqual(hours[12..<24])
        return CustomPersonality(name: title, format: "{phrase}\(joiner){hour}", slots: slots,
                                 hours: halves ? Array(hours[0..<12]) : hours, nextHourFrom: hourAdvanceSlot)
    }
}

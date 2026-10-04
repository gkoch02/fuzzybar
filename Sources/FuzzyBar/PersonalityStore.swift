import Combine
import Foundation

/// Which personality the menubar uses, the ones imported from files, and
/// where both are kept between launches.
@MainActor
final class PersonalityStore: ObservableObject {
    @Published var personality: Personality {
        didSet {
            defaults.set(personality.rawValue, forKey: Personality.defaultsKey)
            onChange?()
        }
    }
    /// Imported from files, in the order they came in.
    @Published private(set) var customPersonalities: [CustomPersonality] {
        didSet {
            defaults.set(try? JSONEncoder().encode(customPersonalities), forKey: Self.customListKey)
            if activeCustom == nil { customPersonalityID = nil }
            onChange?()
        }
    }
    /// The custom personality in use, if any; it stands in front of
    /// `personality`, which stays where it was so removing the custom one
    /// goes back to it.
    @Published var customPersonalityID: UUID? {
        didSet {
            defaults.set(customPersonalityID?.uuidString, forKey: Self.customActiveKey)
            onChange?()
        }
    }
    static let customListKey = "customPersonalities"
    static let customActiveKey = "customPersonality"
    /// Called after any change, once the new value is in place. `Clock` uses
    /// it to reschedule, since phrase boundaries differ between personalities.
    var onChange: (() -> Void)?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.string(forKey: Personality.defaultsKey)
        personality = saved.flatMap(Personality.stored) ?? .default
        let customs = defaults.data(forKey: Self.customListKey)
            .flatMap { try? JSONDecoder().decode([CustomPersonality].self, from: $0) } ?? []
        customPersonalities = customs
        let active = defaults.string(forKey: Self.customActiveKey).flatMap(UUID.init(uuidString:))
        customPersonalityID = customs.contains { $0.id == active } ? active : nil
        if active != nil, customPersonalityID == nil { defaults.removeObject(forKey: Self.customActiveKey) }
        // A renamed or withdrawn value read back as something else; write the
        // current spelling so it only migrates once. didSet does not run
        // during init, so do it by hand.
        if let saved, saved != personality.rawValue {
            defaults.set(personality.rawValue, forKey: Personality.defaultsKey)
        }
    }

    var activeCustom: CustomPersonality? { customPersonalities.first { $0.id == customPersonalityID } }

    /// The active personality's phrase for a clock time, for the Preferences example.
    func phrase(hour: Int, minute: Int) -> String {
        activeCustom?.phrase(hour: hour, minute: minute)
            ?? FuzzyTime.phrase(hour: hour, minute: minute, personality: personality)
    }

    /// Adds an imported personality and switches to it. One with the same
    /// name as an existing one replaces it, keeping its place, so editing a
    /// file and importing it again updates it. Returns whether it replaced.
    @discardableResult
    func importPersonality(_ imported: CustomPersonality) -> Bool {
        var incoming = imported
        if let i = customPersonalities.firstIndex(where: { $0.name.caseInsensitiveCompare(imported.name) == .orderedSame }) {
            incoming.id = customPersonalities[i].id
            customPersonalities[i] = incoming
            customPersonalityID = incoming.id
            return true
        }
        customPersonalities.append(incoming)
        customPersonalityID = incoming.id
        return false
    }

    /// Reads, checks and imports a personality file, and says how it went
    /// in words for Preferences. Import and drag-and-drop both land here.
    func importPersonality(from url: URL) -> PersonalityMessage {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let personality = try CustomPersonality.decode(try Data(contentsOf: url))
            let replaced = importPersonality(personality)
            var text = replaced ? "Updated \(personality.name)." : "Imported \(personality.name)."
            let longest = personality.longestReading
            if longest.count > SpecialTime.maxLength {
                text += " Its longest reading, \"\(longest)\", is \(longest.count) characters; past \(SpecialTime.maxLength) it can end up behind the notch."
            }
            return PersonalityMessage(text: text)
        } catch let error as CustomPersonality.ImportError {
            return PersonalityMessage(text: error.errorDescription ?? "That file couldn't be imported.", isError: true)
        } catch {
            return PersonalityMessage(text: "Couldn't read \(url.lastPathComponent).", isError: true)
        }
    }

    func removePersonality(id: UUID) {
        customPersonalities.removeAll { $0.id == id }
    }
}

/// What the last import or save said, shown under the personality example.
struct PersonalityMessage: Equatable {
    var text: String
    var isError = false
}

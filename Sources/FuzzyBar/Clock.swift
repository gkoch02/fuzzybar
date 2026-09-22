import AppKit
import Combine

/// Updates at phrase boundaries, or each minute while the popover is visible.
@MainActor
final class Clock: ObservableObject {
    @Published private(set) var now: Date
    @Published var personality: Personality {
        didSet {
            defaults.set(personality.rawValue, forKey: Personality.defaultsKey)
            // Phrase boundaries differ between personalities (spoken flips at
            // :58, the ported ones at :00), so the pending tick may be wrong.
            scheduleNextTick()
        }
    }
    @Published var specialTimes: [SpecialTime] {
        didSet {
            SpecialTimes.save(specialTimes, to: defaults)
            scheduleNextTick()
        }
    }
    /// Imported from files, in the order they came in.
    @Published private(set) var customPersonalities: [CustomPersonality] {
        didSet {
            defaults.set(try? JSONEncoder().encode(customPersonalities), forKey: Self.customListKey)
            if activeCustom == nil { customPersonalityID = nil }
            scheduleNextTick()
        }
    }
    /// The custom personality in use, if any; it stands in front of
    /// `personality`, which stays where it was so removing the custom one
    /// goes back to it.
    @Published var customPersonalityID: UUID? {
        didSet {
            defaults.set(customPersonalityID?.uuidString, forKey: Self.customActiveKey)
            scheduleNextTick()
        }
    }
    static let customListKey = "customPersonalities"
    static let customActiveKey = "customPersonality"
    private let defaults: UserDefaults
    private var timer: Timer?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var popoverVisible = false
    private let dateProvider: () -> Date

    init(dateProvider: @escaping () -> Date = Date.init, defaults: UserDefaults = .standard) {
        self.dateProvider = dateProvider
        self.defaults = defaults
        now = dateProvider()
        let saved = defaults.string(forKey: Personality.defaultsKey)
        personality = saved.flatMap(Personality.stored) ?? .default
        specialTimes = SpecialTimes.load(from: defaults)
        let customs = defaults.data(forKey: Self.customListKey)
            .flatMap { try? JSONDecoder().decode([CustomPersonality].self, from: $0) } ?? []
        customPersonalities = customs
        let active = defaults.string(forKey: Self.customActiveKey).flatMap(UUID.init(uuidString:))
        customPersonalityID = customs.contains { $0.id == active } ? active : nil
        if active != nil, customPersonalityID == nil { defaults.removeObject(forKey: Self.customActiveKey) }
        // A pre-rename value ("hal", "cthulhu") reads back as the personality
        // it became, and a withdrawn one ("klingon", "belter") reads back as
        // the default; either way write the current spelling so it only
        // migrates once. didSet does not run during init, so do it by hand.
        if let saved, saved != personality.rawValue {
            defaults.set(personality.rawValue, forKey: Personality.defaultsKey)
        }
        scheduleNextTick()
        observe(.NSSystemClockDidChange, in: .default)
        observe(.NSSystemTimeZoneDidChange, in: .default)
        observe(NSWorkspace.didWakeNotification, in: NSWorkspace.shared.notificationCenter)
    }

    deinit {
        timer?.invalidate()
        for (center, token) in observers { center.removeObserver(token) }
    }

    var activeCustom: CustomPersonality? { customPersonalities.first { $0.id == customPersonalityID } }

    var fuzzy: String {
        Self.text(for: now, personality: personality, custom: activeCustom, specialTimes: specialTimes)
    }

    /// The active personality's phrase for a clock time, for the Preferences example.
    func phrase(hour: Int, minute: Int) -> String {
        activeCustom?.phrase(hour: hour, minute: minute)
            ?? FuzzyTime.phrase(hour: hour, minute: minute, personality: personality)
    }

    /// What the menubar reads at `date`: a special time wins over everything,
    /// then a custom personality, then the built-in one.
    nonisolated static func text(for date: Date, calendar: Calendar = .current, personality: Personality,
                                 custom: CustomPersonality? = nil, specialTimes: [SpecialTime]) -> String {
        if let special = SpecialTimes.text(for: date, calendar: calendar, userTimes: specialTimes) { return special }
        guard let custom else { return FuzzyTime.phrase(for: date, calendar: calendar, personality: personality) }
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return custom.phrase(hour: c.hour ?? 0, minute: c.minute ?? 0)
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

    func removePersonality(id: UUID) {
        customPersonalities.removeAll { $0.id == id }
    }

    /// When the pending tick fires; exposed for tests.
    var timerFireDate: Date? { timer?.fireDate }

    func setPopoverVisible(_ visible: Bool) {
        popoverVisible = visible
        refresh()
    }

    func refresh() {
        now = dateProvider()
        scheduleNextTick()
    }

    private func observe(_ name: Notification.Name, in center: NotificationCenter) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        observers.append((center, token))
    }

    /// Search actual minute boundaries so DST and non-whole-hour time zones work.
    /// Special times last one minute, so they show up here as a change at
    /// their start and another at their end, like any phrase boundary.
    static func nextTick(after date: Date, popoverVisible: Bool, calendar: Calendar = .current,
                         personality: Personality = .default, custom: CustomPersonality? = nil,
                         specialTimes: [SpecialTime] = []) -> Date {
        let minuteStart = calendar.dateInterval(of: .minute, for: date)!.start
        func text(_ d: Date) -> String {
            Self.text(for: d, calendar: calendar, personality: personality, custom: custom, specialTimes: specialTimes)
        }
        let phrase = text(date)
        for offset in 1...5 {
            let candidate = minuteStart.addingTimeInterval(Double(offset) * 60)
            if popoverVisible || text(candidate) != phrase {
                return candidate.addingTimeInterval(0.05)
            }
        }
        return minuteStart.addingTimeInterval(300.05)
    }

    private func scheduleNextTick() {
        timer?.invalidate()
        let fireDate = Self.nextTick(after: dateProvider(), popoverVisible: popoverVisible,
                                     personality: personality, custom: activeCustom, specialTimes: specialTimes)
        let t = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        // Allow coalescing without visibly delaying the minute display.
        t.tolerance = popoverVisible ? 0.1 : 1
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

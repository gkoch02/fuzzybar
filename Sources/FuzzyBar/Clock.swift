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

    var fuzzy: String { Self.text(for: now, personality: personality, specialTimes: specialTimes) }

    /// What the menubar reads at `date`: a special time, else the phrase.
    nonisolated static func text(for date: Date, calendar: Calendar = .current, personality: Personality,
                     specialTimes: [SpecialTime]) -> String {
        SpecialTimes.text(for: date, calendar: calendar, userTimes: specialTimes)
            ?? FuzzyTime.phrase(for: date, calendar: calendar, personality: personality)
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
                         personality: Personality = .default, specialTimes: [SpecialTime] = []) -> Date {
        let minuteStart = calendar.dateInterval(of: .minute, for: date)!.start
        func text(_ d: Date) -> String {
            Self.text(for: d, calendar: calendar, personality: personality, specialTimes: specialTimes)
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
                                     personality: personality, specialTimes: specialTimes)
        let t = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        // Allow coalescing without visibly delaying the minute display.
        t.tolerance = popoverVisible ? 0.1 : 1
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

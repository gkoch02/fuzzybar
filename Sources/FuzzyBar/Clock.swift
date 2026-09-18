import AppKit
import Combine

/// Updates at phrase boundaries, or each minute while the popover is visible.
@MainActor
final class Clock: ObservableObject {
    @Published private(set) var now: Date
    private var timer: Timer?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var popoverVisible = false
    private let dateProvider: () -> Date

    init(dateProvider: @escaping () -> Date = Date.init) {
        self.dateProvider = dateProvider
        now = dateProvider()
        scheduleNextTick()
        observe(.NSSystemClockDidChange, in: .default)
        observe(.NSSystemTimeZoneDidChange, in: .default)
        observe(NSWorkspace.didWakeNotification, in: NSWorkspace.shared.notificationCenter)
    }

    deinit {
        timer?.invalidate()
        for (center, token) in observers { center.removeObserver(token) }
    }

    var fuzzy: String { FuzzyTime.phrase(for: now) }

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
    static func nextTick(after date: Date, popoverVisible: Bool, calendar: Calendar = .current) -> Date {
        let minuteStart = calendar.dateInterval(of: .minute, for: date)!.start
        let phrase = FuzzyTime.phrase(for: date, calendar: calendar)
        for offset in 1...5 {
            let candidate = minuteStart.addingTimeInterval(Double(offset) * 60)
            if popoverVisible || FuzzyTime.phrase(for: candidate, calendar: calendar) != phrase {
                return candidate.addingTimeInterval(0.05)
            }
        }
        return minuteStart.addingTimeInterval(300.05)
    }

    private func scheduleNextTick() {
        timer?.invalidate()
        let fireDate = Self.nextTick(after: dateProvider(), popoverVisible: popoverVisible)
        let t = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        // Allow coalescing without visibly delaying the minute display.
        t.tolerance = popoverVisible ? 0.1 : 1
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

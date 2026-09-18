import Foundation
import Combine

/// Publishes the current time, ticking on minute boundaries.
@MainActor
final class Clock: ObservableObject {
    @Published private(set) var now = Date()
    private var timer: Timer?

    init() {
        scheduleNextTick()
        NotificationCenter.default.addObserver(
            forName: .NSSystemClockDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    var fuzzy: String { FuzzyTime.phrase(for: now) }

    private func tick() {
        now = Date()
        scheduleNextTick()
    }

    /// Fire just after the next :00 seconds so the menubar text is never stale.
    private func scheduleNextTick() {
        timer?.invalidate()
        let interval = 60 - Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 60) + 0.05
        let t = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        t.tolerance = 0
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

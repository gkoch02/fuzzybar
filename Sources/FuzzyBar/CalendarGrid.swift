import Foundation

/// Six complete local-calendar weeks, including the first day of the month.
enum CalendarGrid {
    static func weeks(containing date: Date, calendar: Calendar) -> [[Date]] {
        guard let monthStart = calendar.dateInterval(of: .month, for: date)?.start,
              let gridStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start
        else { return [] }
        return (0..<6).map { week in
            (0..<7).compactMap { day in
                calendar.date(byAdding: .day, value: week * 7 + day, to: gridStart)
            }
        }
    }
}

import SwiftUI

/// A month grid with week numbers, styled after the system clock popover.
struct CalendarView: View {
    let today: Date
    @State private var shownMonth: Date

    private let cal = Calendar.current

    init(today: Date) {
        self.today = today
        _shownMonth = State(initialValue: today)
    }

    var body: some View {
        VStack(spacing: 6) {
            header
            weekdayRow
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 0) {
                    Text(week.isEmpty ? "" : "\(cal.component(.weekOfYear, from: week[0]))")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .frame(width: 22)
                    ForEach(week, id: \.self) { day in
                        dayCell(day)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(shownMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
            Button("Today") { shownMonth = today }.font(.caption)
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.borderless)
        .padding(.bottom, 2)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 22, height: 1)
            ForEach(orderedWeekdaySymbols, id: \.self) { s in
                Text(s.uppercased())
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let inMonth = cal.isDate(day, equalTo: shownMonth, toGranularity: .month)
        let isToday = cal.isDate(day, inSameDayAs: today)
        return Text("\(cal.component(.day, from: day))")
            .font(.callout)
            .fontWeight(isToday ? .bold : .regular)
            .foregroundStyle(isToday ? Color.white : (inMonth ? Color.primary : Color.secondary.opacity(0.5)))
            .frame(width: 28, height: 26)
            .background(isToday ? Circle().fill(Color.accentColor) : nil)
            .frame(maxWidth: .infinity)
    }

    private var orderedWeekdaySymbols: [String] {
        let short = cal.shortWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(short[first...] + short[..<first]).map { String($0.prefix(3)) }
    }

    /// Six rows of seven days, starting from the first weekday on/before the 1st.
    private var weeks: [[Date]] {
        CalendarGrid.weeks(containing: shownMonth, calendar: cal)
    }

    private func shift(_ months: Int) {
        if let d = cal.date(byAdding: .month, value: months, to: shownMonth) { shownMonth = d }
    }
}

import SwiftUI

/// Preferences' list of special times, with a one-line form to add another.
struct SpecialTimesSection: View {
    @EnvironmentObject private var clock: Clock
    @State private var time = Calendar.current.date(from: DateComponents(hour: 15, minute: 14)) ?? Date()
    @State private var text = ""
    @State private var yearly = false
    @State private var month = 1
    @State private var day = 1

    /// February gets 29 so a leap-day birthday can be set; it fires in leap years.
    private static let daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    private var trimmed: String { text.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Special times")
            // Past a few rows the list scrolls, or a long one would push the
            // window off the screen.
            if clock.specialTimes.count > Self.visibleRows {
                ScrollView { list }
                    .frame(height: (CGFloat(Self.visibleRows) + 0.5) * Self.rowHeight)
            } else {
                list
            }
            HStack {
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                TextField("Text", text: $text, prompt: Text("pi o'clock"))
                    .onChange(of: text) { _, new in
                        if new.count > SpecialTime.maxLength { text = String(new.prefix(SpecialTime.maxLength)) }
                    }
                    .onSubmit(add)
            }
            HStack {
                Picker("Repeat", selection: $yearly) {
                    Text("Every day").tag(false)
                    Text("One day a year").tag(true)
                }
                .labelsHidden()
                .fixedSize()
                Spacer(minLength: 0)
                Button("Add", action: add).disabled(trimmed.isEmpty)
            }
            if yearly {
                HStack {
                    Picker("Month", selection: $month) {
                        ForEach(1...12, id: \.self) { Text(Calendar.current.monthSymbols[$0 - 1]).tag($0) }
                    }
                    .onChange(of: month) { _, new in day = min(day, Self.daysInMonth[new - 1]) }
                    Picker("Day", selection: $day) {
                        ForEach(1...Self.daysInMonth[month - 1], id: \.self) { Text("\($0)").tag($0) }
                    }
                }
                .labelsHidden()
            }
            Text("Replaces the phrase for that one minute, in every personality. Up to \(SpecialTime.maxLength) characters, so it clears the notch.")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static let visibleRows = 5
    private static let rowHeight: CGFloat = 22

    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(clock.specialTimes) { special in
                HStack(spacing: 6) {
                    Text(Self.when(special)).monospacedDigit().foregroundStyle(.secondary)
                    Text(special.text).lineLimit(1)
                    Spacer(minLength: 0)
                    Button {
                        clock.specialTimes.removeAll { $0.id == special.id }
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Remove \(special.text)")
                }
                .font(.callout)
                .frame(height: Self.rowHeight)
            }
        }
    }

    private func add() {
        guard !trimmed.isEmpty else { return }
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        clock.specialTimes.append(SpecialTime(hour: c.hour ?? 0, minute: c.minute ?? 0,
                                              month: yearly ? month : nil, day: yearly ? day : nil,
                                              text: trimmed))
        text = ""
    }

    /// "3:14 PM" or "Mar 14, 3:14 PM", in the user's own time format.
    static func when(_ special: SpecialTime) -> String {
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: special.month ?? 1,
                                                              day: special.day ?? 1, hour: special.hour,
                                                              minute: special.minute)) ?? Date()
        let time = date.formatted(date: .omitted, time: .shortened)
        guard special.month != nil else { return time }
        return "\(date.formatted(.dateTime.month(.abbreviated).day())), \(time)"
    }
}

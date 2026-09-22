import SwiftUI

@main
struct FuzzyBarApp: App {
    @StateObject private var clock = Clock()
    @StateObject private var sun = SunSettings()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra(clock.fuzzy) {
            PopoverView(now: clock.now, sun: sun, openSettings: { openSettings() })
                .onAppear { clock.setPopoverVisible(true) }
                .onDisappear { clock.setPopoverVisible(false) }
        }
        .menuBarExtraStyle(.window)

        Settings { SettingsView().environmentObject(clock).environmentObject(sun) }
    }
}

struct PopoverView: View {
    let now: Date
    @ObservedObject var sun: SunSettings
    let openSettings: () -> Void
    @State private var popover = PopoverWindow()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(now, format: .dateTime.hour().minute())
                    .font(.system(size: 22, weight: .medium))
                Text(now, format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .foregroundStyle(.secondary)
                SunView(now: now, settings: sun)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)

            Divider().padding(.horizontal, 12)

            CalendarView(today: now)
                .padding(.horizontal, 12).padding(.vertical, 10)

            Divider().padding(.horizontal, 12)

            VStack(alignment: .leading, spacing: 2) {
                menuRow("Preferences…") {
                    // Re-center a window that was closed and start it unfocused;
                    // leave an open one where it is, focus and all.
                    let reopening = SettingsWindow.current.flatMap { $0.isVisible ? nil : $0 }
                    reopening?.center()
                    // A menu closes when you pick an item; the popover should too.
                    popover.window?.close()
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                    if let reopening { SettingsWindow.clearFocus(reopening) }
                }
                menuRow("Quit") { NSApp.terminate(nil) }
            }
            .padding(8)
        }
        .frame(width: 270)
        .background(PopoverWindow.Reader(popover: popover))
    }

    private func menuRow(_ title: String, action: @escaping () -> Void) -> some View {
        MenuRowButton(title: title, action: action)
    }
}

private struct MenuRowButton: View {
    let title: String
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 5).fill(hover ? Color.primary.opacity(0.1) : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

/// MenuBarExtra has no API to close its window, and clicking a row inside it
/// doesn't close it the way choosing a menu item would. This holds the
/// window so a row can close it itself.
final class PopoverWindow {
    weak var window: NSWindow?

    struct Reader: NSViewRepresentable {
        let popover: PopoverWindow
        func makeNSView(context: Context) -> NSView { View(popover: popover) }
        func updateNSView(_ nsView: NSView, context: Context) {}

        private final class View: NSView {
            let popover: PopoverWindow
            init(popover: PopoverWindow) {
                self.popover = popover
                super.init(frame: .zero)
            }
            required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                popover.window = window
            }
        }
    }
}

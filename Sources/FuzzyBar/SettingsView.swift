import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @StateObject private var login = LoginSettings()
    @EnvironmentObject private var clock: Clock

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                Text("FuzzyBar")
                    .font(.title2).fontWeight(.semibold)
                Text("Version \(version)")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Tells the time in words, the way you'd say it out loud. Click the menubar for the exact time and a calendar.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Picker("Personality", selection: $clock.personality) {
                    ForEach(Personality.allCases) { Text($0.title).tag($0) }
                }
                Text(clock.personality.note)
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(FuzzyTime.phrase(hour: 20, minute: 40, personality: clock.personality))
                    .font(.callout.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
                    .accessibilityLabel("Example at 8:40 pm")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Start at login", isOn: Binding(
                    get: { login.isRequested }, set: { login.setEnabled($0) }
                ))
                if login.status == .requiresApproval {
                    Text("Approval is needed in System Settings before FuzzyBar can start at login.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Login Items…") { SMAppService.openSystemSettingsLoginItems() }
                }
                if let error = login.error {
                    Text(error).font(.caption).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            Text("© 2026 PlumpBug. Made with love and no Rosetta.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 320)
        .onAppear { login.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            login.refresh()
        }
    }
}

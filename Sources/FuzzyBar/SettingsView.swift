import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var startAtLogin = SMAppService.mainApp.status == .enabled
    @State private var error: String?

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
                Toggle("Start at login", isOn: $startAtLogin)
                    .onChange(of: startAtLogin) { _, on in
                        do {
                            if on { try SMAppService.mainApp.register() }
                            else { try SMAppService.mainApp.unregister() }
                            error = nil
                        } catch {
                            self.error = error.localizedDescription
                            startAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            Text("© 2026 GKoch. Made with love and no Rosetta.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 320)
        .onAppear { startAtLogin = SMAppService.mainApp.status == .enabled }
    }
}

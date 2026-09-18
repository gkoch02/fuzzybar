import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var startAtLogin = SMAppService.mainApp.status == .enabled
    @State private var error: String?

    var body: some View {
        Form {
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
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear { startAtLogin = SMAppService.mainApp.status == .enabled }
    }
}

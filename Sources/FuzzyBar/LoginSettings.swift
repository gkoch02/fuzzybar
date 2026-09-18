import Combine
import ServiceManagement

@MainActor
final class LoginSettings: ObservableObject {
    @Published private(set) var status: SMAppService.Status
    @Published private(set) var error: String?
    private let readStatus: () -> SMAppService.Status
    private let register: () throws -> Void
    private let unregister: () throws -> Void

    init(readStatus: @escaping () -> SMAppService.Status = { SMAppService.mainApp.status },
         register: @escaping () throws -> Void = { try SMAppService.mainApp.register() },
         unregister: @escaping () throws -> Void = { try SMAppService.mainApp.unregister() }) {
        self.readStatus = readStatus
        self.register = register
        self.unregister = unregister
        status = readStatus()
    }

    // The toggle represents the requested registration, including pending approval.
    var isRequested: Bool { status == .enabled || status == .requiresApproval }

    func refresh() { status = readStatus() }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled { try register() } else { try unregister() }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        refresh()
    }
}

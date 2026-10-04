import XCTest
import ServiceManagement
@testable import FuzzyBar

final class LoginSettingsTests: XCTestCase {
    /// Stands in for SMAppService: registering leaves it pending approval,
    /// unregistering clears it, and each call is counted.
    private final class FakeService {
        var status = SMAppService.Status.notRegistered
        var registrations = 0
        var unregistrations = 0
    }

    @MainActor private func settings(_ fake: FakeService) -> LoginSettings {
        LoginSettings(readStatus: { fake.status }, register: {
            fake.registrations += 1
            fake.status = .requiresApproval
        }, unregister: {
            fake.unregistrations += 1
            fake.status = .notRegistered
        })
    }

    @MainActor func testPendingLoginApprovalAndExternalRefreshDoNotRegisterAgain() {
        let fake = FakeService()
        let login = settings(fake)
        login.setEnabled(true)
        XCTAssertTrue(login.isRequested)
        XCTAssertEqual(login.status, .requiresApproval)
        XCTAssertNil(login.error)
        fake.status = .enabled
        login.refresh()
        XCTAssertTrue(login.isRequested)
        fake.status = .requiresApproval
        login.refresh()
        XCTAssertTrue(login.isRequested)
        XCTAssertEqual(fake.registrations, 1)
        XCTAssertEqual(fake.unregistrations, 0)
        login.setEnabled(false)
        XCTAssertEqual(login.status, .notRegistered)
        XCTAssertEqual(fake.unregistrations, 1)
    }

    @MainActor func testPendingRegistrationCanBeCancelledThroughToggle() {
        let fake = FakeService()
        let login = settings(fake)
        XCTAssertFalse(login.isRequested)
        login.setEnabled(!login.isRequested)
        XCTAssertTrue(login.isRequested)
        XCTAssertEqual(login.status, .requiresApproval)
        login.setEnabled(!login.isRequested)
        XCTAssertFalse(login.isRequested)
        XCTAssertEqual(login.status, .notRegistered)
        XCTAssertEqual(fake.registrations, 1)
        XCTAssertEqual(fake.unregistrations, 1)
    }

    @MainActor func testFailedLoginChangeRestoresActualStateWithoutRetry() {
        enum Failure: Error { case denied }
        var calls = 0
        let login = LoginSettings(readStatus: { .enabled }, register: {}, unregister: {
            calls += 1
            throw Failure.denied
        })
        login.setEnabled(false)
        XCTAssertTrue(login.isRequested)
        XCTAssertNotNil(login.error)
        XCTAssertEqual(calls, 1)
    }
}

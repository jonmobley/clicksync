import Foundation
import ServiceManagement

// MARK: - Launch At Login Manager
@MainActor
final class LaunchAtLoginManager: ObservableObject {
	@Published private(set) var isEnabled: Bool

	init() {
		isEnabled = SMAppService.mainApp.status == .enabled
	}

	func setEnabled(_ enabled: Bool, logger: DebugLogger?) {
		do {
			if enabled {
				try SMAppService.mainApp.register()
			} else {
				try SMAppService.mainApp.unregister()
			}
			isEnabled = enabled
			logger?.log("Launch at login \(enabled ? "enabled" : "disabled")")
		} catch {
			isEnabled = SMAppService.mainApp.status == .enabled
			logger?.log("Launch at login failed: \(error.localizedDescription)")
		}
	}
}

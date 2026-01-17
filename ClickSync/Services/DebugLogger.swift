import Foundation

// MARK: - Debug Logger
final class DebugLogger: ObservableObject {
	@Published var isEnabled: Bool

	init(isEnabled: Bool) {
		self.isEnabled = isEnabled
	}

	func log(_ message: String) {
		guard isEnabled else { return }
		print("[ClickSync] \(message)")
	}
}

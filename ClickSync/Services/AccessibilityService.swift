import AppKit
import ApplicationServices
import Foundation

// MARK: - Accessibility Service
final class AccessibilityService {
	var isTrusted: Bool {
		AXIsProcessTrusted()
	}

	func requestAccess() {
		let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
		let options = [key: true] as CFDictionary
		AXIsProcessTrustedWithOptions(options)
	}

	func openAccessibilitySettings() {
		guard let url = URL(
			string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
		) else { return }
		NSWorkspace.shared.open(url)
	}
}

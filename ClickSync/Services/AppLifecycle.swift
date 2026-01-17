import AppKit
import Foundation

// MARK: - App Lifecycle
enum AppLifecycle {
	static func configureApp() {
		NSApplication.shared.setActivationPolicy(.accessory)
	}
}

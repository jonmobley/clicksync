import AppKit
import Foundation

// MARK: - Presentation App Checker
final class PresentationAppChecker {
	private let allowedBundleIDs: Set<String> = [
		"com.microsoft.Powerpoint",
		"com.microsoft.PowerPoint",
		"com.apple.iWork.Keynote"
	]

	func isPresentationAppActive() -> Bool {
		guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
			return false
		}
		return allowedBundleIDs.contains(bundleID)
	}

	func isPresentationAppRunning() -> Bool {
		let runningApps = NSWorkspace.shared.runningApplications
		return runningApps.contains { app in
			guard let bundleID = app.bundleIdentifier else { return false }
			return allowedBundleIDs.contains(bundleID)
		}
	}
}

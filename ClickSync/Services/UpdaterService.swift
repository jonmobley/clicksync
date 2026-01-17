import Foundation
import Sparkle

// MARK: - Sparkle Updater Service
final class UpdaterService: ObservableObject {
	private let updaterController: SPUStandardUpdaterController

	// Sparkle setup notes:
	// - Versioning: update CFBundleShortVersionString and CFBundleVersion in Info.plist for each release.
	// - Appcast: publish an appcast.xml to GitHub Releases (e.g. https://github.com/ORG/REPO/releases/latest/download/appcast.xml).
	// - Release time: generate a Sparkle signature with your private key and include it in the appcast item.
	// - Public key: set SUPublicEDKey in Info.plist to match the Sparkle keypair you generate.
	init() {
		updaterController = SPUStandardUpdaterController(
			startingUpdater: true,
			updaterDelegate: nil,
			userDriverDelegate: nil
		)
		updaterController.updater.automaticallyChecksForUpdates = true
		// Enable automatic downloads so Sparkle can install silently.
		updaterController.updater.automaticallyDownloadsUpdates = true
	}

	func checkForUpdates() {
		updaterController.updater.checkForUpdatesInBackground()
	}
}

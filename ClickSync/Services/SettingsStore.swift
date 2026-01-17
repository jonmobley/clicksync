import Foundation

// MARK: - Settings Store
final class SettingsStore: ObservableObject {
	private enum Keys {
		static let role = "clicksync.role"
		static let followerHost = "clicksync.followerHost"
		static let port = "clicksync.port"
		static let debugLogging = "clicksync.debugLogging"
		static let selectedPeerName = "clicksync.selectedPeerName"
	}

	@Published var role: AppRole {
		didSet { UserDefaults.standard.set(role.rawValue, forKey: Keys.role) }
	}

	@Published var followerHost: String {
		didSet { UserDefaults.standard.set(followerHost, forKey: Keys.followerHost) }
	}

	@Published var portString: String {
		didSet { UserDefaults.standard.set(portString, forKey: Keys.port) }
	}

	@Published var debugLogging: Bool {
		didSet { UserDefaults.standard.set(debugLogging, forKey: Keys.debugLogging) }
	}

	@Published var selectedPeerName: String {
		didSet { UserDefaults.standard.set(selectedPeerName, forKey: Keys.selectedPeerName) }
	}

	init() {
		let defaults = UserDefaults.standard
		let roleValue = defaults.string(forKey: Keys.role)
		role = AppRole(rawValue: roleValue ?? "") ?? .controller
		followerHost = defaults.string(forKey: Keys.followerHost) ?? ""
		portString = defaults.string(forKey: Keys.port) ?? "54545"
		debugLogging = defaults.bool(forKey: Keys.debugLogging)
		selectedPeerName = defaults.string(forKey: Keys.selectedPeerName) ?? ""
	}

	var portValue: UInt16? {
		UInt16(portString)
	}
}

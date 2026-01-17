import Foundation

// MARK: - App State
@MainActor
final class AppState: ObservableObject {
	@Published private(set) var connectionStatus: ConnectionStatus = .disconnected
	@Published private(set) var accessibilityTrusted: Bool = false
	@Published private(set) var peers: [DiscoveredPeer] = []
	@Published private(set) var connectedPeerName: String?
	private var autoPortRetryCount = 0

	let settings: SettingsStore
	let accessibility: AccessibilityService
	let presentationChecker: PresentationAppChecker
	let launchAtLogin: LaunchAtLoginManager
	let updaterService: UpdaterService
	let inputMonitor: InputMonitor
	let keySender: KeySender
	let connectionManager: ConnectionManager
	let logger: DebugLogger

	init() {
		settings = SettingsStore()
		accessibility = AccessibilityService()
		presentationChecker = PresentationAppChecker()
		launchAtLogin = LaunchAtLoginManager()
		updaterService = UpdaterService()
		inputMonitor = InputMonitor()
		keySender = KeySender()
		connectionManager = ConnectionManager()
		logger = DebugLogger(isEnabled: settings.debugLogging)
		accessibilityTrusted = accessibility.isTrusted
		wireCallbacks()
		start()
	}

	func start() {
		applySettings()
	}

	func applySettings() {
		logger.isEnabled = settings.debugLogging
		refreshAccessibilityStatus()
		switch settings.role {
		case .controller:
			startController()
		case .follower:
			startFollower()
		}
	}

	func triggerTest(_ command: SlideCommand) {
		switch settings.role {
		case .controller:
			sendCommand(command)
		case .follower:
			executeCommand(command)
		}
	}

	func requestAccessibilityIfNeeded() {
		accessibility.requestAccess()
		refreshAccessibilityStatus()
	}

	func refreshAccessibilityStatus() {
		accessibilityTrusted = accessibility.isTrusted
	}

	private func wireCallbacks() {
		connectionManager.onStatusChange = { [weak self] status in
			self?.connectionStatus = status
			self?.handleAutoPortRecoveryIfNeeded(for: status)
		}
		connectionManager.onCommandReceived = { [weak self] command in
			self?.handleRemote(command)
		}
		connectionManager.onPeersUpdate = { [weak self] peers in
			self?.handlePeersUpdate(peers)
		}
		connectionManager.onConnectedPeerChange = { [weak self] name in
			self?.connectedPeerName = name
		}
		inputMonitor.onCommand = { [weak self] command in
			self?.handleLocal(command)
		}
	}

	private func startController() {
		let started = inputMonitor.start()
		if !started {
			logger.log("Input monitor failed to start. Check accessibility permissions.")
		}
		requestAccessibilityIfNeeded()
		connectionManager.startController(preferredPeerName: settings.selectedPeerName)
	}

	private func startFollower() {
		inputMonitor.stop()
		requestAccessibilityIfNeeded()
		guard let port = settings.portValue else {
			connectionStatus = .failed("Invalid port")
			return
		}
		connectionManager.startFollower(port: port)
	}

	private func handleLocal(_ command: SlideCommand) {
		guard settings.role == .controller else { return }
		sendCommand(command)
	}

	private func handleRemote(_ command: SlideCommand) {
		guard settings.role == .follower else { return }
		executeCommand(command)
	}

	private func handlePeersUpdate(_ peers: [DiscoveredPeer]) {
		self.peers = peers
		if !peers.contains(where: { $0.name == settings.selectedPeerName }) {
			settings.selectedPeerName = ""
		}
	}

	private func sendCommand(_ command: SlideCommand) {
		guard presentationChecker.isPresentationAppActive() else {
			logger.log("Ignored command: no presentation app active.")
			return
		}
		logger.log("Sending \(command.rawValue)")
		connectionManager.send(command: command)
	}

	private func executeCommand(_ command: SlideCommand) {
		guard presentationChecker.isPresentationAppActive() else {
			logger.log("Ignored command: no presentation app active.")
			return
		}
		logger.log("Executing \(command.rawValue)")
		keySender.send(command)
	}

	func checkForUpdates() {
		updaterService.checkForUpdates()
	}

	private func handleAutoPortRecoveryIfNeeded(for status: ConnectionStatus) {
		switch status {
		case .failed(let message):
			guard settings.role == .follower else { return }
			guard message.localizedCaseInsensitiveContains("address already in use") else { return }
			guard autoPortRetryCount < 5 else { return }
			autoPortRetryCount += 1
			settings.portString = nextPortString()
			startFollower()
		case .listening:
			autoPortRetryCount = 0
		default:
			break
		}
	}

	private func nextPortString() -> String {
		let current = settings.portValue ?? 54545
		let next = current >= 65535 ? 54545 : current + 1
		return String(next)
	}
}

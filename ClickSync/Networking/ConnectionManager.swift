import Foundation
import Network

// MARK: - Connection Manager
final class ConnectionManager {
	private enum Bonjour {
		static let serviceType = "_clicksync._tcp"
		static let serviceName = "ClickSync"
	}

	private let queue = DispatchQueue(label: "clicksync.connection")
	private var listener: NWListener?
	private var connection: NWConnection?
	private var browser: NWBrowser?
	private var receiveBuffer = Data()
	private var reconnectWorkItem: DispatchWorkItem?
	private var preferredPeerName: String?
	private var discoveredPeers: [DiscoveredPeer] = []
	private var connectedPeerName: String?

	var onStatusChange: ((ConnectionStatus) -> Void)?
	var onCommandReceived: ((SlideCommand) -> Void)?
	var onPeersUpdate: (([DiscoveredPeer]) -> Void)?
	var onConnectedPeerChange: ((String?) -> Void)?

	func startController(preferredPeerName: String?) {
		stop()
		self.preferredPeerName = preferredPeerName
		startBrowser()
	}

	func startFollower(port: UInt16) {
		stop()
		setStatus(.listening)
		startListener(on: port)
	}

	func stop() {
		reconnectWorkItem?.cancel()
		reconnectWorkItem = nil
		listener?.cancel()
		listener = nil
		browser?.cancel()
		browser = nil
		connection?.cancel()
		connection = nil
		setConnectedPeerName(nil)
		receiveBuffer.removeAll()
		notifyPeers([])
		setStatus(.disconnected)
	}

	func send(command: SlideCommand) {
		guard let message = SyncMessage(command: command) else { return }
		send(payload: message.payload)
	}

	private func connect(to endpoint: NWEndpoint, name: String) {
		let connection = NWConnection(to: endpoint, using: .tcp)
		setConnectedPeerName(name)
		self.connection = connection
		setupConnection(connection)
		connection.start(queue: queue)
	}

	private func startListener(on port: UInt16) {
		guard let nwPort = NWEndpoint.Port(rawValue: port) else {
			setStatus(.failed("Invalid port"))
			return
		}
		do {
			let listener = try NWListener(using: .tcp, on: nwPort)
			let serviceName = Host.current().localizedName ?? Bonjour.serviceName
			listener.service = NWListener.Service(name: serviceName, type: Bonjour.serviceType)
			self.listener = listener
			listener.newConnectionHandler = { [weak self] connection in
				self?.accept(connection: connection)
			}
			listener.stateUpdateHandler = { [weak self] state in
				self?.handleListenerState(state)
			}
			listener.start(queue: queue)
		} catch {
			setStatus(.failed(error.localizedDescription))
		}
	}

	private func accept(connection: NWConnection) {
		self.connection?.cancel()
		self.connection = connection
		setupConnection(connection)
		connection.start(queue: queue)
	}

	private func setupConnection(_ connection: NWConnection) {
		connection.stateUpdateHandler = { [weak self] state in
			self?.handleConnectionState(state)
		}
	}

	private func handleListenerState(_ state: NWListener.State) {
		switch state {
		case .failed(let error):
			setStatus(.failed(error.localizedDescription))
		default:
			break
		}
	}

	private func handleConnectionState(_ state: NWConnection.State) {
		switch state {
		case .ready:
			setStatus(.connected)
			notifyConnectedPeer()
			receiveNext()
		case .waiting:
			setStatus(.connecting)
		case .failed(let error):
			setStatus(.failed(error.localizedDescription))
			scheduleReconnectIfNeeded()
		case .cancelled:
			setStatus(.disconnected)
			setConnectedPeerName(nil)
		default:
			break
		}
	}

	private func receiveNext() {
		connection?.receive(minimumIncompleteLength: 1, maximumLength: 512) { [weak self] data, _, isComplete, error in
			if let data = data, !data.isEmpty {
				self?.handleReceivedData(data)
			}
			if isComplete || error != nil {
				self?.connection?.cancel()
				self?.scheduleReconnectIfNeeded()
				return
			}
			self?.receiveNext()
		}
	}

	private func handleReceivedData(_ data: Data) {
		receiveBuffer.append(data)
		while let range = receiveBuffer.range(of: Data([0x0A])) {
			let lineData = receiveBuffer.subdata(in: receiveBuffer.startIndex..<range.lowerBound)
			receiveBuffer.removeSubrange(receiveBuffer.startIndex..<range.upperBound)
			if let line = String(data: lineData, encoding: .utf8) {
				handleLine(line.trimmingCharacters(in: .whitespacesAndNewlines))
			}
		}
	}

	private func handleLine(_ line: String) {
		guard let message = SyncMessage(rawValue: line) else { return }
		onCommandReceived?(message.command)
	}

	private func send(payload: Data) {
		guard let connection = connection else { return }
		connection.send(content: payload, completion: .contentProcessed { _ in })
	}

	private func scheduleReconnectIfNeeded() {
		scheduleReconnectToDiscoveredPeer()
	}

	private func scheduleReconnectToDiscoveredPeer() {
		reconnectWorkItem?.cancel()
		let workItem = DispatchWorkItem { [weak self] in
			self?.connectToPreferredPeer()
		}
		reconnectWorkItem = workItem
		queue.asyncAfter(deadline: .now() + 1.0, execute: workItem)
	}

	private func startBrowser() {
		let parameters = NWParameters.tcp
		let browser = NWBrowser(
			for: .bonjour(type: Bonjour.serviceType, domain: nil),
			using: parameters
		)
		self.browser = browser
		setConnectedPeerName(nil)
		browser.browseResultsChangedHandler = { [weak self] results, _ in
			self?.handleBrowseResults(results)
		}
		browser.stateUpdateHandler = { [weak self] state in
			self?.handleBrowserState(state)
		}
		browser.start(queue: queue)
		setStatus(.connecting)
	}

	private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
		let peers = results.compactMap { result -> DiscoveredPeer? in
			switch result.endpoint {
			case .service(let name, _, _, _):
				return DiscoveredPeer(name: name, endpoint: result.endpoint)
			default:
				return nil
			}
		}
		discoveredPeers = peers.sorted { $0.name < $1.name }
		notifyPeers(discoveredPeers)
		connectToPreferredPeer()
	}

	private func handleBrowserState(_ state: NWBrowser.State) {
		switch state {
		case .failed(let error):
			setStatus(.failed(error.localizedDescription))
		default:
			break
		}
	}

	private func connectToPreferredPeer() {
		guard connection == nil || connectedPeerName == nil else { return }
		guard !discoveredPeers.isEmpty else {
			setStatus(.connecting)
			return
		}
		let preferred = discoveredPeers.first { $0.name == preferredPeerName } ?? discoveredPeers.first
		guard let peer = preferred else { return }
		connect(to: peer.endpoint, name: peer.name)
	}

	private func notifyPeers(_ peers: [DiscoveredPeer]) {
		DispatchQueue.main.async { [weak self] in
			self?.onPeersUpdate?(peers)
		}
	}

	private func notifyConnectedPeer() {
		DispatchQueue.main.async { [weak self] in
			self?.onConnectedPeerChange?(self?.connectedPeerName)
		}
	}

	private func setConnectedPeerName(_ name: String?) {
		connectedPeerName = name
		notifyConnectedPeer()
	}

	private func setStatus(_ status: ConnectionStatus) {
		DispatchQueue.main.async { [weak self] in
			self?.onStatusChange?(status)
		}
	}
}

import Foundation
import Network

// MARK: - Discovered Peer
struct DiscoveredPeer: Identifiable, Equatable {
	let id: String
	let name: String
	let endpoint: NWEndpoint

	init(name: String, endpoint: NWEndpoint) {
		self.id = name
		self.name = name
		self.endpoint = endpoint
	}
}

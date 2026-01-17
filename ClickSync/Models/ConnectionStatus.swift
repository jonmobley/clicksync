import Foundation

// MARK: - Connection Status
enum ConnectionStatus: Equatable {
	case disconnected
	case connecting
	case listening
	case connected
	case failed(String)

	var statusText: String {
		switch self {
		case .disconnected:
			return "Disconnected"
		case .connecting:
			return "Connecting"
		case .listening:
			return "Listening"
		case .connected:
			return "Connected"
		case .failed(let message):
			return "Error: \(message)"
		}
	}

	var isConnected: Bool {
		switch self {
		case .connected:
			return true
		default:
			return false
		}
	}
}

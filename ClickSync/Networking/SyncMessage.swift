import Foundation

// MARK: - Sync Message
enum SyncMessage: String {
	case next = "NEXT"
	case previous = "PREV"
	case ping = "PING"
	case pong = "PONG"

	init?(command: SlideCommand) {
		switch command {
		case .next:
			self = .next
		case .previous:
			self = .previous
		}
	}

	func commandOrNil() -> SlideCommand? {
		switch self {
		case .next:
			return .next
		case .previous:
			return .previous
		case .ping, .pong:
			return nil
		}
	}

	var payload: Data {
		Data((rawValue + "\n").utf8)
	}
}

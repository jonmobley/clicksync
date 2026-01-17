import Foundation

// MARK: - Sync Message
enum SyncMessage: String {
	case next = "NEXT"
	case previous = "PREV"

	init?(command: SlideCommand) {
		switch command {
		case .next:
			self = .next
		case .previous:
			self = .previous
		}
	}

	var command: SlideCommand {
		switch self {
		case .next:
			return .next
		case .previous:
			return .previous
		}
	}

	var payload: Data {
		Data((rawValue + "\n").utf8)
	}
}

import Foundation

// MARK: - Slide Command
enum SlideCommand: String, CaseIterable {
	case next
	case previous

	var displayName: String {
		switch self {
		case .next:
			return "Next Slide"
		case .previous:
			return "Previous Slide"
		}
	}

	var keyCode: UInt16 {
		switch self {
		case .next:
			return 124
		case .previous:
			return 123
		}
	}
}

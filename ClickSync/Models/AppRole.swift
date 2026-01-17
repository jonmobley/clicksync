import Foundation

// MARK: - App Role
enum AppRole: String, CaseIterable, Identifiable {
	case controller
	case follower

	var id: String { rawValue }

	var displayName: String {
		switch self {
		case .controller:
			return "Controller"
		case .follower:
			return "Follower"
		}
	}
}

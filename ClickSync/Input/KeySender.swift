import AppKit
import CoreGraphics
import Foundation

// MARK: - Key Sender
final class KeySender {
	func send(_ command: SlideCommand) {
		postKey(CGKeyCode(command.keyCode))
	}

	private func postKey(_ keyCode: CGKeyCode) {
		let source = CGEventSource(stateID: .hidSystemState)
		let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
		let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
		keyDown?.post(tap: .cghidEventTap)
		keyUp?.post(tap: .cghidEventTap)
	}
}

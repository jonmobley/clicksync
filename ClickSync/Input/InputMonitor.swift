import AppKit
import CoreGraphics
import Foundation

// MARK: - Input Monitor
final class InputMonitor {
	private var eventTap: CFMachPort?
	private var runLoopSource: CFRunLoopSource?

	var onCommand: ((SlideCommand) -> Void)?

	func start() -> Bool {
		guard eventTap == nil else { return true }
		guard let tap = createTap() else { return false }
		eventTap = tap
		let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
		runLoopSource = source
		CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
		CGEvent.tapEnable(tap: tap, enable: true)
		return true
	}

	func stop() {
		guard let tap = eventTap else { return }
		CGEvent.tapEnable(tap: tap, enable: false)
		if let source = runLoopSource {
			CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
		}
		eventTap = nil
		runLoopSource = nil
	}

	private func createTap() -> CFMachPort? {
		let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
		let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
			let monitor = Unmanaged<InputMonitor>.fromOpaque(userInfo!).takeUnretainedValue()
			return monitor.handleEvent(proxy: proxy, type: type, event: event)
		}
		return CGEvent.tapCreate(
			tap: .cgSessionEventTap,
			place: .headInsertEventTap,
			options: .defaultTap,
			eventsOfInterest: mask,
			callback: callback,
			userInfo: Unmanaged.passUnretained(self).toOpaque()
		)
	}

	private func handleEvent(
		proxy: CGEventTapProxy,
		type: CGEventType,
		event: CGEvent
	) -> Unmanaged<CGEvent>? {
		if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
			if let tap = eventTap {
				CGEvent.tapEnable(tap: tap, enable: true)
			}
			return Unmanaged.passUnretained(event)
		}
		guard type == .keyDown else {
			return Unmanaged.passUnretained(event)
		}
		let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat)
		guard isRepeat == 0 else {
			return Unmanaged.passUnretained(event)
		}
		let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
		if let command = command(for: keyCode) {
			onCommand?(command)
		}
		return Unmanaged.passUnretained(event)
	}

	private func command(for keyCode: Int64) -> SlideCommand? {
		switch keyCode {
		case 124, 49:
			return .next
		case 123:
			return .previous
		default:
			return nil
		}
	}
}

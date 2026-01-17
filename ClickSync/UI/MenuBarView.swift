import AppKit
import SwiftUI

// MARK: - Menu Bar View
struct MenuBarView: View {
	@ObservedObject var appState: AppState
	@ObservedObject private var settings: SettingsStore

	init(appState: AppState) {
		self.appState = appState
		self.settings = appState.settings
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			statusHeader
			roleSelector
			roleDetails
			Divider()
			testButtons
			Divider()
			launchAtLoginToggle
			Divider()
			checkForUpdatesButton
			Divider()
			debugToggle
			accessibilitySection
			Divider()
			quitButton
		}
		.padding(12)
		.frame(width: 260)
	}

	private var roleSelector: some View {
		HStack(spacing: 6) {
			roleButton(for: .controller)
			roleButton(for: .follower)
		}
	}

	private func roleButton(for role: AppRole) -> some View {
		Button {
			guard settings.role != role else { return }
			settings.role = role
			appState.applySettings()
		} label: {
			HStack(spacing: 4) {
				if settings.role == role {
					Image(systemName: "checkmark")
						.font(.caption2)
				}
				Text(role.displayName)
					.fontWeight(settings.role == role ? .semibold : .regular)
			}
		}
		.buttonStyle(.plain)
		.controlSize(.small)
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
		.background(selectionBackground(isSelected: settings.role == role))
	}

	private func selectionBackground(isSelected: Bool) -> some View {
		let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
		if isSelected {
			return AnyView(shape.fill(Color.accentColor.opacity(0.2)))
		}
		return AnyView(shape.stroke(Color.secondary.opacity(0.3)))
	}

	@ViewBuilder
	private var roleDetails: some View {
		switch settings.role {
		case .controller:
			EmptyView()
		case .follower:
			followerDetails
		}
	}

	private var followerDetails: some View {
		VStack(alignment: .leading, spacing: 4) {
			Button("Restart Listener") {
				appState.applySettings()
			}
		}
	}

	private var testButtons: some View {
		VStack(alignment: .leading, spacing: 6) {
			Button("Test Next Slide") {
				appState.triggerTest(.next)
			}
			Button("Test Previous Slide") {
				appState.triggerTest(.previous)
			}
		}
	}

	private var launchAtLoginToggle: some View {
		Toggle("Launch at Login", isOn: Binding(
			get: { appState.launchAtLogin.isEnabled },
			set: { appState.launchAtLogin.setEnabled($0, logger: appState.logger) }
		))
	}

	private var checkForUpdatesButton: some View {
		Button("Check for Updates...") {
			appState.checkForUpdates()
		}
	}

	private var debugToggle: some View {
		Toggle("Debug Log", isOn: $settings.debugLogging)
			.onChange(of: settings.debugLogging) { _ in
				appState.applySettings()
			}
	}

	private var accessibilitySection: some View {
		Group {
			if !appState.accessibilityTrusted {
				Text("Accessibility access is required.")
					.font(.caption)
				HStack {
					Button("Request Access") {
						appState.requestAccessibilityIfNeeded()
					}
					Button("Open Settings") {
						appState.accessibility.openAccessibilitySettings()
					}
				}
			}
		}
	}

	private var quitButton: some View {
		Button("Quit ClickSync") {
			NSApplication.shared.terminate(nil)
		}
	}
}

// MARK: - Status Header
extension MenuBarView {
	private var statusHeader: some View {
		HStack(spacing: 6) {
			Circle()
				.fill(appState.connectionStatus.isConnected ? Color.green : Color.red)
				.frame(width: 8, height: 8)
			Text(statusTitle)
				.font(.caption)
		}
	}

	private var statusTitle: String {
		if appState.connectionStatus.isConnected,
		   let name = appState.connectedPeerName,
		   !name.isEmpty {
			return "Connected to \(name)"
		}
		return appState.connectionStatus.statusText
	}
}

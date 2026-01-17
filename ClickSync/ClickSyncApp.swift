import AppKit
import SwiftUI

// MARK: - ClickSync App
@main
struct ClickSyncApp: App {
	@StateObject private var appState = AppState()

	init() {
		AppLifecycle.configureApp()
	}

	var body: some Scene {
		MenuBarExtra {
			MenuBarView(appState: appState)
		} label: {
			ZStack {
				Image("MenuBarIcon")
				if appState.connectionStatus.isConnected {
					Circle()
						.fill(Color.green)
						.frame(width: 6, height: 6)
				}
			}
		}
		.menuBarExtraStyle(.menu)
	}
}

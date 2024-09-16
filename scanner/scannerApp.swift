//
//  scannerApp.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import CoreSpotlight

@main
struct scannerApp: App {
	@Environment(\.scenePhase) var scenePhase
	let persistenceController = PersistenceController.shared
	
	init() {
		AppState.shared.viewState = .Home
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
				.onContinueUserActivity(CSSearchableItemActionType, perform: handleSpotlight)
				.onOpenURL { url in
					if url.absoluteString.contains("scan") {
						AppState.shared.viewState = .Page
					}
				}
		}
		.onChange(of: scenePhase) { newPhase in
			if newPhase == .active {
				// App is active again
			} else if newPhase == .inactive {
				saveAppState()
			} else if newPhase == .background {
				saveAppState()
			}
		}
	}
	
	func handleSpotlight(_ userActivity: NSUserActivity) {
		if let id = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
			if let uri = URL(string: id) {
				if let scan = persistenceController.scanFromUri(uri) {
					print("****** Found a scan")
					AppState.shared.openScan = scan
				} else if let recognizedItem = persistenceController.recognizedItemFromUri(uri) {
					print("****** Found a recognizedItem")
					AppState.shared.openScan = recognizedItem.parent?.parent
				}
			}
		}
	}
	
	func saveAppState() {
	}
}


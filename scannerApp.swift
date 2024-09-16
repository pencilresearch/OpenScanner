//
//  scannerApp.swift
//  scanner
//
//  Created by Slaven Radic on 2022-07-21.
//

import SwiftUI

@main
struct scannerApp: App {
	@Environment(\.scenePhase) var scenePhase
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
	
	func saveAppState() {
	}
}

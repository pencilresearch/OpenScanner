//
//  Persistence.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import CoreData

struct PersistenceController {
	static let shared = PersistenceController()
	
	private (set) var spotlightIndexer: NSCoreDataCoreSpotlightDelegate?
	
	let container: NSPersistentCloudKitContainer
	
	init(inMemory: Bool = false) {
		container = NSPersistentCloudKitContainer(name: "scanner")
		
		guard let description = container.persistentStoreDescriptions.first else {
			fatalError("###\(#function): Failed to retrieve a persistent store description.")
		}
		
		description.type = NSSQLiteStoreType
		description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
		description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
		
		if inMemory {
			// Preview and in memory experiments
			description.url = URL(fileURLWithPath: "/dev/null")
			description.cloudKitContainerOptions = nil
		}
		
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		
		spotlightIndexer = NSCoreDataCoreSpotlightDelegate(
			forStoreWith: description,
			coordinator: container.persistentStoreCoordinator
		)
		spotlightIndexer?.startSpotlightIndexing()
		
		if !inMemory {
			// Permanent store options
			container.viewContext.automaticallyMergesChangesFromParent = true
			container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		}
	}
	
	func scanFromUri(_ uri: URL) -> Scan? {
		guard let objectID = container.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri)
		else {
			return nil
		}
		return container.viewContext.object(with: objectID) as? Scan
	}
	
	func recognizedItemFromUri(_ uri: URL) -> ScanRecognizedItem? {
		guard let objectID = container.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri)
		else {
			return nil
		}
		return container.viewContext.object(with: objectID) as? ScanRecognizedItem
	}
	
	static var preview: PersistenceController = {
		let result = PersistenceController(inMemory: true)
		let viewContext = result.container.viewContext
		for _ in 0..<2 {
			let newScan = Scan(context: viewContext)
			newScan.timestamp = Date()
			for _ in 0..<4 {
				let newPage = ScanCapture(context: viewContext)
				newPage.timestamp = Date()
				for index in 0..<3 {
					let newItem = ScanRecognizedItem(context: viewContext)
					newItem.timestamp = Date()
					newItem.transcript = "Transcript \(index)"
				}
			}
		}
		do {
			try viewContext.save()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nsError = error as NSError
			fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
		return result
	}()
	
}

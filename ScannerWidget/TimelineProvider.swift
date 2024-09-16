//
//  TimelineProvider.swift
//  ScannerWidgetExtension
//
//  Created by Slaven Radic on 2024-09-01.
//


import WidgetKit
import Intents
import CoreData
import SwiftUI

struct Provider: IntentTimelineProvider {
	
	var viewContext : NSManagedObjectContext

	init(context : NSManagedObjectContext) {
		self.viewContext = context
	}
	
	func placeholder(in context: Context) -> ScanArrayEntry {
		createEntry()
	}

	func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (ScanArrayEntry) -> ()) {
		let entry = createEntry()
		completion(entry)
	}

	func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<ScanArrayEntry>) -> ()) {
		
		try? viewContext.setQueryGenerationFrom(.current)
		viewContext.refreshAllObjects()

		var entries: [ScanArrayEntry] = []
		
		let sort = NSSortDescriptor(key: "order", ascending: true)
		
		let sortDescriptor = NSSortDescriptor(keyPath: \Scan.order, ascending: true)
		let request = NSFetchRequest<Scan>(entityName: "Scan")
		request.sortDescriptors = [sort]
		do {
			let dates = try viewContext.fetch(request)
			
			entries.append(createEntry())
		}
		catch {
			entries.append(createEntry())
		}
		let timeline = Timeline(entries: entries, policy: .atEnd)
		completion(timeline)

	}
	
	func createEntry(_ scans: [Scan] = [], configuration: ConfigurationIntent? = nil) -> ScanArrayEntry {
		
		var entries: [ScanEntry] = []
		if scans.count > 0 {
			for scan in scans {
				let entry = ScanEntry(title: scan.title)
				entries.append(entry)
				if entries.count > 5 {
					break
				}
			}
		} else {
			entries.append(ScanEntry(title: ""))
		}
		return ScanArrayEntry(
			date: Date(),
			configuration: configuration ?? ConfigurationIntent(),
			entries: entries
		)
	}
}

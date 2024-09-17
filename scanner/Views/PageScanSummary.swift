//
//  PageScanSummary.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import VisionKit
import CoreData

struct PageScanSummary: View {
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.presentationMode) var presentationMode
	
	@ObservedObject var scan: Scan
	
	// Used when instantiating from scanner
	public var reducedControls = false
	
	@State private var editMode = EditMode.inactive
	@State private var deleteConfirmation = false
	
	@State private var titleValue = ""
	
	@State var backgroundGradient = LinearGradient(colors: [Color(hex: 0xf2fbff), Color(hex: 0xe2ebf0)], startPoint: .top, endPoint: .bottom)
	
	
	var body: some View {
		ZStack {
			
			listOfCaptures
				.scrollContentBackground(.hidden)
				.toolbarBackground(Color("gradientMainBottom"), for: .navigationBar)
		}
		.background(DefaultBackgroundGradient)
		.navigationBarItems(
			trailing:
				HStack(spacing: 16) {
					if !reducedControls {
						Button {
							editMode = editMode == .active ? .inactive : .active
						} label: {
							Label("Edit", systemImage: "chevron.up.chevron.down")
								.labelStyle(.titleAndIcon)
								.foregroundColor(Color.primary)
						}
						.foregroundColor(editMode == .active ? Color.white : Color.accent)
						.padding(.trailing, 10)
						.background(
							RoundedRectangle(cornerRadius: 8, style: .continuous)
								.fill(editMode == .active ? Color.accent : Color.clear)
						)
						
						Button { shareSheet() } label: {
							Label("Share", systemImage: "square.and.arrow.up")
								.labelStyle(.titleAndIcon)
								.foregroundColor(Color.primary)
						}
					}
				}
		)
		.navigationBarTitleDisplayMode(.inline)
		.onAppear {
			titleValue = scan.title ?? ""
		}
	}
	
	var listOfCaptures: some View {
		List {
			
			scanTitle
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
			
			ForEach (scan.capturesArray, id: \.self) { capture in
				
				if capture.imageData != nil {
					NavigationLink(destination: QuickLookView(scanCapture: capture)) {
						captureRow(capture)
					}
					.listRowBackground(Color.clear)
					.listRowSeparator(.hidden)
				}
			}
			.onDelete(perform: deleteItems)
			.onMove(perform: moveItems)
			.listRowBackground(Color.clear)
			.listRowSeparator(.hidden)
			
		}
		.listStyle(.plain)
		.environment(\.editMode, $editMode)
		
	}
	
	func captureRow(_ capture: ScanCapture) -> some View {
		HStack {
			SmallThumbnail(image: capture.thumbnail)
			VStack(alignment: .leading, spacing: 8) {
				Text("Page \(capture.order + 1)")
					.bold()
				Text(capture.textPreview)
					.font(.caption)
					.italic()
					.lineLimit(2)
			}
			.padding(8)
		}
		
	}
	
	var scanTitle: some View {
		TextField("Scan title", text: $titleValue)
			.onChange(of: titleValue, perform: { changed in
				scan.title = changed
			})
	}
	
	func close() {
		self.presentationMode.wrappedValue.dismiss()
	}
	
	func shareSheet() {
		if let url = scan.pdfDocumentFile() {
			let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
		}
	}
	
	func deleteScan() {
		viewContext.delete(scan)
		saveContext()
		close()
	}
	
	func moveItems(from source: IndexSet, to destination: Int) {
		
		var revisedItems: [ScanCapture] = scan.capturesArray.map{ $0 }
		revisedItems.move(fromOffsets: source, toOffset: destination)
		
		for reverseIndex in stride(
			from: revisedItems.count - 1,
			through: 0,
			by: -1
		) {
			revisedItems[reverseIndex].order = Int32(reverseIndex)
		}
		saveContext()
	}
	
	private func deleteItems(offsets: IndexSet) {
		withAnimation {
			offsets.map { scan.capturesArray[$0] }.forEach(viewContext.delete)
			
			do {
				try viewContext.save()
			} catch {
				let nsError = error as NSError
				fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
			}
		}
	}
	
	func saveContext() {
		if viewContext.hasChanges {
			do {
				try viewContext.save()
			} catch {
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
	
}

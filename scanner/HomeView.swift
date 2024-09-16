//
//  HomeView.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import AppIntents
import CoreMotion

struct HomeView: View {
	
	@Environment(\.managedObjectContext) private var viewContext
	@ObservedObject var navigationManager = NavigationManager.shared
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \Scan.order, ascending: false)],
		animation: .default)
	private var scans: FetchedResults<Scan>
	
	@State private var selectedScan: Scan?
	@State private var importSelection = false
	
	@State private var searchText = ""
	
	let motionManager = CMMotionManager()
	let queue = OperationQueue()
	@State private var pitch = Double.zero
	@State private var yaw = Double.zero
	@State private var roll = Double.zero
	
	@State private var transparentGradient =
	LinearGradient(
		colors: [
			Color(hex: 0x9999bb).opacity(0.1),
			Color(hex: 0x777799).opacity(0.2)],
		startPoint: .topLeading,
		endPoint: .bottomTrailing)
	
	@State var isEditMode: EditMode = .inactive
	
	var body: some View {
		ZStack {
			Color.clear
			
			VStack {
				
				listOfScans
					.ios16scrollContentBackground()
				
			}
			
			// Show bottom Start Scan button
			VStack {
				Spacer()
				startScanBottomBar
			}
		}
		.searchable(text: $searchText, placement: .toolbar)
		.confirmationDialog(
			"Import",
			isPresented: $importSelection
		) {
			Button {  } label: {
				Text("Import PDF")
			}
			Button {  } label: {
				Text("Import photos")
			}
		}
		.navigationBarItems(
			trailing:
				HStack {
				}
		)
		.ios16toolbarBackground(Color("gradientMainBottom"))
		.ignoresSafeArea(edges: .bottom)
		.onChange(of: navigationManager.requestedClassicScan) { newValue in
			if newValue {
				AppState.shared.viewState = .Page
			}
		}
		.onAppear {
			if AppState.shared.isSpeaking {
				AppState.shared.stopSpeaking()
			}
		}
	}
	
	var listOfScans: some View {
		List {
			ForEach (scans, id: \.self) { scan in
				
				if (searchText == "") || (scan.containsText(searchText)) {
					
					NavigationLink(destination: LiveScanSummary(scan: scan)) {
						scanItem(scan)
							.swipeActions(edge: .leading) {
								Button {
									scan.fave = !scan.fave
								} label: {
									Label("Fave", systemImage: "star")
								}
								.tint(.accent)
							}
						
							.swipeActions(edge: .trailing) {
								Button(role: .destructive) {
									viewContext.delete(scan)
									saveContext()
								} label: {
									Label("Delete", systemImage: "trash")
								}
							}
					}
				}
			}
			.onDelete(perform: deleteItems)
			.onMove(perform: moveItems)
			.listRowBackground(Color.clear)
			.listRowSeparator(.hidden)
			
			Spacer()
				.frame(height: 40)
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
			
			if searchText == "" {
				AboutView()
					.listRowBackground(Color.clear)
					.listRowSeparator(.hidden)
					.padding(.top, 40)
					.padding(.bottom, 100)
			}
			
		}
		.listStyle(.plain)
		.environment(\.editMode, self.$isEditMode)
		
	}
	
	func scanItem(_ scan: Scan) -> some View {
		
		VStack(alignment: .leading) {
			
			let maxTiles = 3
			
			ZStack {
				
				// Create blank spots
				HStack(alignment: .center, spacing: 12) {
					ForEach (0..<maxTiles) { index in
						CaptureThumbnail(capture: nil)
					}
					Spacer()
				}
				
				// Overlay real scan captures
				HStack(alignment: .center, spacing: 12) {
					
					ForEach (scan.capturesArray, id: \.id) { capture in
						
						if capture.order < maxTiles {
							CaptureThumbnail(capture: capture)
						}
					}
					
					Spacer()
				}
				
			}
			.overlay(
				ZStack(alignment: .trailing) {
					if scan.capturesArray.count > maxTiles {
						Color.clear
						
						VStack {
							Text("+\(scan.capturesArray.count - maxTiles)")
								.bold()
							Text("more")
								.font(.caption)
						}
						.foregroundColor(Color.white)
						.padding(12)
						.background(
							Circle()
								.fill(Color.gray)
						)
					}
				}
					.padding(.trailing, 16)
			)
			
			HStack(alignment: .bottom, spacing: 4) {
				if scan.fave {
					Image(systemName: "star.fill")
						.foregroundColor(Color.yellow)
				}
				Text(scan.title != nil && scan.title! != "" ? scan.title! : "Untitled")
					.lineLimit(1)
				Text(scan.timestamp!, style: .relative)
					.font(.caption)
					.opacity(0.5)
			}
		}
		.padding(.vertical, 8)
		.id(scan.lastUpdate)
	}
	
	var startScanBottomBar: some View {
		HStack {
			
			Spacer()
			
			ScanStartPicker()
				.padding()
		}
		.padding(.bottom, 8)
	}
	
	func moveItems(from source: IndexSet, to destination: Int) {
		
		var revisedItems: [Scan] = scans.map{ $0 }
		revisedItems.move(fromOffsets: source, toOffset: destination)
		
		for reverseIndex in stride(
			from: revisedItems.count - 1,
			through: 0,
			by: -1
		) {
			revisedItems[reverseIndex].order = Int32(scans.count - reverseIndex - 1)
		}
		saveContext()
	}
	
	private func deleteItems(offsets: IndexSet) {
		withAnimation {
			offsets.map { scans[$0] }.forEach(viewContext.delete)
			// Reorder remaining scans
			var i = scans.count - 1
			for scan in scans {
				scan.order = Int32(i)
				i -= 1
			}
			saveContext()
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
	
	func switchView(_ viewState: ViewState) {
		withAnimation(.easeInOut) {
			if AppState.shared.viewState == .About && viewState == .About {
				AppState.shared.viewState = .Home
			} else {
				AppState.shared.viewState = viewState
			}
		}
	}
	
}

struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		HomeView()
			.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
	}
}

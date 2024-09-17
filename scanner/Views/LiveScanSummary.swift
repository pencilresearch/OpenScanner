//
//  LiveScanSummary.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import VisionKit
import CoreData
import MapKit
import QuickLook

struct LiveScanSummary: View {
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.presentationMode) var presentationMode
	
	@ObservedObject var scan: Scan
	
	@State private var deleteConfirmation = false
	
	@State private var titleValue = ""
	@State private var showTimeline = true
	@State private var showMap = false
	
	@State private var showingMenuFor: ScanRecognizedItem?
	@State private var editing = false
	
	// Set last review prompt date default to a year ago, for new installs
	@AppStorage("lastReviewPrompt") private var lastReviewPrompt: Date = Date().addingTimeInterval(TimeInterval(-365*24*60*60))
	
	@State var backgroundGradient = LinearGradient(colors: [Color(hex: 0xf2fbff), Color(hex: 0xe2ebf0)], startPoint: .top, endPoint: .bottom)
	
	var body: some View {
		ZStack {
			
			VStack {
				if showMap {
					mapView
				}
				
				if showTimeline {
					
					capturesTimeline
					
				} else {
					
					capturesList
					
				}
				
			}
			
		}
		.background(DefaultBackgroundGradient)
		.navigationBarItems(
			leading:
				HStack {
					if AppState.shared.openScan != nil {
						Button { AppState.shared.openScan = nil } label: {
							Label("Scans", systemImage: "chevron.left")
								.labelStyle(.titleAndIcon)
						}
					}
				},
			trailing:
				HStack(spacing: 16) {
					
					
					Button {
						if scan.longitude == 0 && scan.latitude == 0 {
							AppState.shared.locationManager.requestLocation()
							if let location = AppState.shared.locationManager.myLocation {
								scan.latitude = location.coordinate.latitude
								scan.longitude = location.coordinate.longitude
								if scan.longitude != 0 && scan.latitude != 0 {
									showMap.toggle()
								}
							}
						} else {
							showMap.toggle()
						}
					} label: {
						Label( "Map", systemImage: "location.square")
							.labelStyle(.iconOnly)
							.foregroundColor(showMap ? Color.white : Color.primary)
							.background(
								RoundedRectangle(cornerRadius: 4)
									.fill(showMap ? Color.accent : Color.clear)
									.padding(-4)
							)
					}
					.accessibilityLabel("Show scan location")
					
					Button { showTimeline.toggle() } label: {
						Label( showTimeline ? "Timeline" : "Images", systemImage: showTimeline ? "square.fill.text.grid.1x2" : "square.text.square")
							.labelStyle(.iconOnly)
							.foregroundColor(Color.primary)
					}
					.accessibilityLabel(showTimeline ? "Showing scan timeline" : "Showing scan pages")
					
					Menu {
						
						Button { sharePdf() } label: {
							Label("PDF", systemImage: "doc")
								.labelStyle(.titleAndIcon)
								.font(.title3)
								.foregroundColor(Color.primary)
						}
						
						Button { shareText() } label: {
							Label("Text", systemImage: "text.alignleft")
								.labelStyle(.titleAndIcon)
								.font(.title3)
								.foregroundColor(Color.primary)
						}
						
					} label: {
						Label("Share", systemImage: "square.and.arrow.up")
							.labelStyle(.titleAndIcon)
							.foregroundColor(Color.primary)
					}
					
				}
		)
		.iOSScrollDismissesKeyboard()
		.navigationBarTitleDisplayMode(.inline)
		.ignoresSafeArea(edges: .bottom)
		.onAppear {
			titleValue = scan.title ?? ""
			showTimeline = scan.isLive
			print(lastReviewPrompt)
			/// Prompt for review if more than 30 days passed since the last prompt
			if lastReviewPrompt.addingTimeInterval(TimeInterval(30*24*60*60)) < Date() {
				DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
					lastReviewPrompt = Date()
					AppState.shared.requestReview()
				}
			}
		}
	}
	
	var capturesTimeline: some View {
		ZStack(alignment: .topLeading) {
			
			ScrollView {
				VStack {
					
					scanTitle
						.padding(.leading, isMenuShown ? 100 : 0)
						.animation(.default, value: isMenuShown)
					
					ForEach (scan.capturesArray, id: \.self) { capture in
						
						LiveCaptureSummary(capture: capture, showingMenuFor: $showingMenuFor, editing: $editing)
						
					}
					
					Spacer()
						.frame(height: 340)
				}
				.padding()
			}
			
			overlayMenu
				.padding(.top, 30)
				.padding(.leading, 10)
		}
		
	}
	
	
	var overlayMenu: some View {
		
		
		VStack(alignment: .trailing, spacing: 0) {
			
			Button {
				editing.toggle()
				if !editing {
					saveContext()
				}
			} label: {
				if editing {
					SummaryContextButton(caption: "Done", image: "checkmark.square", roundTop: true, roundBottom: true)
					
				} else {
					SummaryContextButton(caption: "Edit", image: "character.cursor.ibeam", roundTop: true, roundBottom: false)
					
				}
			}
			.offset(x: isMenuShown ? 0 : -100)
			.opacity(isMenuShown ? 1 : 0)
			.animation(Animation.easeOut(duration: 0.25).delay(0), value: showingMenuFor)
			
			Button { shareItem(item: showingMenuFor!) } label: {
				SummaryContextButton(caption: "Share", image: "square.and.arrow.up")
			}
			.offset(x: isMenuShown ? 0 : -100)
			.opacity(isMenuShown && !editing ? 1 : 0)
			.animation(Animation.easeOut(duration: 0.25).delay(0.03), value: showingMenuFor)
			
			Button {
				UIPasteboard.general.setValue(showingMenuFor!.transcript!,
											  forPasteboardType: UTType.plainText.identifier)
			} label: {
				SummaryContextButton(caption: "Copy", image: "doc.on.doc")
			}
			.offset(x: isMenuShown ? 0 : -100)
			.opacity(isMenuShown && !editing ? 1 : 0)
			.animation(Animation.easeOut(duration: 0.25).delay(0.06), value: showingMenuFor)
			
			Button {
				if AppState.shared.isSpeaking {
					AppState.shared.stopSpeaking()
				} else {
					AppState.shared.speak(text: showingMenuFor!.transcript)
				}
			} label: {
				SummaryContextButton(caption: "Speak", image: "mouth")
			}
			.offset(x: isMenuShown ? 0 : -100)
			.opacity(isMenuShown && !editing ? 1 : 0)
			.animation(Animation.easeOut(duration: 0.25).delay(0.09), value: showingMenuFor)
			
			Button(role: .destructive) {
				viewContext.delete(showingMenuFor!)
				showingMenuFor = nil
				saveContext()
			} label: {
				SummaryContextButton(caption: "Delete", image: "trash", destructive: true, roundBottom: true)
			}
			.offset(x: isMenuShown ? 0 : -100)
			.opacity(isMenuShown && !editing ? 1 : 0)
			.animation(Animation.easeOut(duration: 0.25).delay(0.12), value: showingMenuFor)
			
			Button { showingMenuFor = nil } label: {
				SummaryContextButton(caption: "Dismiss", image: "xmark", roundTop: true, roundBottom: true, gray: true)
			}
			.offset(x: isMenuShown ? 0 : -100)
			.opacity(isMenuShown && !editing ? 1 : 0)
			.animation(Animation.easeOut(duration: 0.25).delay(0.0), value: showingMenuFor)
			.padding(.top, 30)
			
			
		}
	}
	
	var isMenuShown: Bool {
		showingMenuFor != nil
	}
	
	func shareItem(item: ScanRecognizedItem) {
		if let url = item.textUrl {
			let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
		}
	}
	
	var capturesList: some View {
		
		List {
			
			scanTitle
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
			
			ForEach (scan.capturesArray, id: \.self) { capture in
				captureClassicThumbnail(capture: capture)
					.padding(.trailing, 32)
					.padding(.bottom, 16)
				
			}
			.onDelete(perform: deleteItems)
			.onMove(perform: moveItems)
			.listRowBackground(Color.clear)
			.listRowSeparator(.hidden)
			
			Spacer()
				.frame(height: 340)
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
		}
		.listStyle(.plain)
		.ios16scrollContentBackground()
		
	}
	
	func captureLiveThumbnail(capture: ScanCapture) -> some View {
		NavigationLink(destination: QuickLookView(scanCapture: capture)) {
			Image(uiImage: capture.thumbnail ?? UIImage())
				.resizable()
				.scaledToFill()
				.frame(width: 300, height: 300 * (4/3))
				.clipShape(RoundedRectangle(cornerRadius: 4))
				.shadow(radius: 6)
				.overlay(
					// Page number
					ZStack(alignment: .topTrailing) {
						RoundedRectangle(cornerRadius: 4)
							.stroke(Color.white, lineWidth: 1)
						Text("\(capture.order+1)")
							.padding(8)
							.background(
								ZStack {
									Circle()
										.fill(Color.background)
									Circle()
										.stroke(Color.primary, lineWidth: 1)
								}
							)
							.padding(.trailing, 6)
					}
				)
		}
	}
	
	func captureClassicThumbnail(capture: ScanCapture) -> some View {
		NavigationLink(destination: QuickLookView(scanCapture: capture)) {
			Image(uiImage: capture.thumbnail ?? UIImage())
				.resizable()
				.scaledToFill()
				.frame(width: 300, height: capture.thumbnail != nil ? 300 / capture.thumbnail!.aspectRatio : 300)
				.clipShape(RoundedRectangle(cornerRadius: 4))
				.shadow(radius: 6)
				.overlay(
					// Page number
					ZStack(alignment: .topTrailing) {
						RoundedRectangle(cornerRadius: 4)
							.stroke(Color.white, lineWidth: 1)
						Text("\(capture.order+1)")
							.padding(8)
							.background(
								ZStack {
									Circle()
										.fill(Color.background)
									Circle()
										.stroke(Color.primary, lineWidth: 1)
								}
							)
							.padding(.top, 2)
							.padding(.trailing, 6)
					}
				)
		}
	}
	
	var scanTitle: some View {
		HStack {
			TextField("Scan title", text: $titleValue)
				.font(.title3)
				.background(
					ZStack(alignment: .bottom) {
						Color.clear
						Rectangle()
							.fill(Color.primary.opacity(0.2))
							.frame(height: 1)
					}
				)
				.padding(.vertical)
			
			if scan.title != titleValue {
				Button {
					scan.title = titleValue
					saveContext()
				} label: {
					Text("Save")
						.foregroundColor(Color.white)
						.background(
							RoundedRectangle(cornerRadius: 4)
								.fill(Color.accent)
								.padding(-4)
						)
				}
				.padding(.trailing, 4)
			}
		}
	}
	
	
	var mapView: some View {
		
		Map(coordinateRegion: .constant(
			MKCoordinateRegion(
				center: CLLocationCoordinate2D(
					latitude: scan.latitude,
					longitude: scan.longitude),
				span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))),
			interactionModes: [MapInteractionModes.all],
			showsUserLocation: true,
			userTrackingMode: .none,
			annotationItems: [scan]) { pin in
			MapAnnotation(
				coordinate: CLLocationCoordinate2D(latitude: scan.latitude, longitude: scan.longitude),
				anchorPoint: CGPoint(x: 0.5, y: 0.5)
			) {
				Image(systemName: "mappin")
					.foregroundColor(Color.red)
					.font(.title)
			}
		}
	}
	
	
	func close() {
		self.presentationMode.wrappedValue.dismiss()
	}
	
	func sharePdf() {
		if let url = scan.pdfDocumentFile() {
			let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
		}
	}
	
	func shareText() {
		if let url = scan.textDocument {
			let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
		}
	}
	
	func shareMarkdown() {
		if let url = scan.textDocument {
			let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
		}
	}
	
	func deleteScan() {
		viewContext.delete(scan)
		saveContext()
		close()
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
	
	func moveItems(from source: IndexSet, to destination: Int) {
		
		var revisedItems: [ScanCapture] = scan.capturesArray.map{ $0 }
		revisedItems.move(fromOffsets: source, toOffset: destination)
		
		for reverseIndex in stride(
			from: revisedItems.count - 1,
			through: 0,
			by: -1 ) {
			revisedItems[reverseIndex].order = Int32(reverseIndex)
		}
		
		for index in 0..<scan.capturesArray.count {
			scan.capturesArray[index].order = Int32(index)
		}
		
		saveContext()
		scan.lastUpdate = Date()
	}
	
	private func deleteItems(offsets: IndexSet) {
		withAnimation {
			offsets.map { scan.capturesArray[$0] }.forEach(viewContext.delete)
			
			saveContext()
			
			for index in 0..<scan.capturesArray.count {
				scan.capturesArray[index].order = Int32(index)
			}
			
			saveContext()
			
			scan.lastUpdate = Date()
		}
	}
	
	
}

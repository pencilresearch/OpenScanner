//
//  LiveCaptureSummary.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import UIKit
import Vision
import QuickLook
import AVFoundation

struct LiveCaptureSummary: View {
	@Environment(\.managedObjectContext) private var viewContext
	
	@ObservedObject var capture: ScanCapture
	@Binding var showingMenuFor: ScanRecognizedItem?
	@Binding var editing: Bool
	
	@State var askedToOcr = false
	@State var savedUrl: URL?
	@State var quickLookUrl: URL?
	@State var ocrActive = false
	
	@State var backgroundGradient = LinearGradient(colors: [Color(hex: 0xf2fbff), Color(hex: 0xe2ebf0)], startPoint: .top, endPoint: .bottom)
	
	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			
			NavigationLink(destination: QuickLookView(scanCapture: capture)) {
				SmallThumbnail(image: capture.thumbnail)
					.opacity(showingMenuFor == nil || showingMenuFor == nil ? 1 : 0)
					.animation(.default, value: showingMenuFor)
			}
			.accessibilityLabel("View scan image")
			
			LazyVStack(alignment: .leading) {
				
				listOfRecognizedItems
					.opacity(showingMenuFor == nil || showingMenuFor?.parent == capture ? 1 : 0.5)
				
				Rectangle()
					.fill(Color.clear)
					.frame(height: 1)
			}
		}
	}
	
	var listOfRecognizedItems: some View {
		VStack {
			
			if capture.recognizedItemsArray.count > 0 {
				
				ForEach (capture.recognizedItemsArray, id: \.self) { item in
					
					RecognizedItemView(item: item, readOnly: false, showingMenuFor: $showingMenuFor, editing: $editing)
					
				}
				
			} else {
				Spacer()
			}
			
		}
	}
	
	var imageThumbnail: some View {
		Image(uiImage: capture.thumbnail ?? UIImage())
			.resizable()
			.scaledToFit()
			.shadow(radius: 6)
			.padding()
			.frame(height: 240)
	}
	
	func shareImage() {
		guard let data = capture.thumbnail else { return }
		let item = ShareImage(placeholderItem: data)
		let activityViewController = UIActivityViewController(activityItems: [item], applicationActivities: nil)
		
		UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
	}
	
	func shareText() {
		if let url = capture.textDocument {
			let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
		}
	}
	
	var ocrButton: some View {
		Button { } label: {
			Label("Detect text", systemImage: "text.viewfinder")
		}
		.padding(.top)
	}
	
	func performOcr() {
		ocrActive = true
		guard let data = capture.imageData else { return }
		guard let image = UIImage(data: data) else { return }
		
		// Get the CGImage on which to perform requests.
		guard let cgImage = image.cgImage else { return }
		
		// Create a new image-request handler.
		let requestHandler = VNImageRequestHandler(cgImage: cgImage)
		
		// Create a new request to recognize text.
		let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
		
		do {
			// Perform the text-recognition request.
			try requestHandler.perform([request])
		} catch {
			print("Unable to perform the requests: \(error).")
		}
		
	}
	
	func recognizeTextHandler(request: VNRequest, error: Error?) {
		guard let observations =
				request.results as? [VNRecognizedTextObservation] else {
			return
		}
		let recognizedStrings = observations.compactMap { observation in
			// Return the string of the top VNRecognizedText instance.
			return observation.topCandidates(1).first?.string
		}
		
		// Process the recognized strings.
		processOcrResults(recognizedStrings)
	}
	
	func processOcrResults(_ found: [String]) {
		for text in found {
			let item = ScanRecognizedItem(context: viewContext)
			item.id = UUID()
			item.order = Int32(capture.recognizedItemsArray.count)
			item.timestamp = Date()
			item.transcript = text
			capture.addToRecognizedItems(item)
		}
		
		askedToOcr = true
		ocrActive = false
		saveContext()
	}
	
	private func deleteItems(offsets: IndexSet) {
		withAnimation {
			offsets.map { capture.recognizedItemsArray[$0] }.forEach(viewContext.delete)
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
}

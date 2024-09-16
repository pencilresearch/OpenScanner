//
//  CaptureSummary.swift
//  scanner
//
//  Created by Slaven Radic on 2022-07-27.
//

import SwiftUI
import UIKit
import Vision
import QuickLook

struct CaptureSummary: View {
	@Environment(\.managedObjectContext) private var viewContext
	
	var capture: ScanCapture
	
	@State var imagePresented = false
	@State var askedToOcr = false
	@State var savedUrl: URL?
	@State var quickLookUrl: URL?
	@State var ocrActive = false
	
	var body: some View {
		ZStack {
		
//		VStack(alignment: .leading) {

//			if #available(iOS 16.0, *) {
//				listOfCaptureElements
//					.scrollContentBackground(Color.clear)
//			} else {
				// Fallback on earlier versions
				listOfCaptureElements
//			}
//		}
//		.sheet(isPresented: $imagePresented, content: {
//			QuickLookController(capture: capture)
//		})
			if ocrActive {
				ProgressView()
			}
		}
		.navigationBarItems(
			trailing:
				Menu("Share") {
					Button { shareImage() } label: {
						Label("Share scan image", systemImage: "doc.text.image")
							.labelStyle(.titleAndIcon)
					}
					if capture.recognizedItemsArray.count > 0 {
						Button { shareText() } label: {
							Label("Share text", systemImage: "text.alignleft")
								.labelStyle(.titleAndIcon)
						}
					}
				}
		)
	}
	
	var capturedImage: some View {
		Image(uiImage: UIImage(data: capture.image!) ?? UIImage())
			.resizable()
			.scaledToFit()
			.frame(height: 200)
	}
	
	var listOfCaptureElements: some View {
		List {
			
			if capture.image != nil {
				NavigationLink(destination: QuickLookView(capture: capture)) {
					Image(uiImage: capture.thumbnail ?? UIImage())
						.resizable()
						.scaledToFit()
						.shadow(radius: 6)
						.padding()
						.frame(height: 240)
				}
//				Button { presentImage() } label: {
//					Image(uiImage: capture.thumbnail ?? UIImage())
//						.resizable()
//						.scaledToFit()
//						.shadow(radius: 6)
//						.padding()
//						.frame(height: 240)
//				}
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
			}
			
			if !askedToOcr && capture.recognizedItemsArray.count == 0 && !ocrActive {
				ocrButton
					.listRowBackground(Color.clear)
					.listRowSeparator(.hidden)
			}
			if capture.recognizedItemsArray.count > 0 {
				listOfRecognizedItems
			} else {
				Spacer()
					.listRowBackground(Color.clear)
					.listRowSeparator(.hidden)
			}
			
			footer
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
		}
		.listStyle(.plain)
	}
	
	var listOfRecognizedItems: some View {
			ForEach (capture.recognizedItemsArray, id: \.self) { item in
				
				recognizedView(item)
			}
			.onDelete(perform: deleteItems)
		.listRowBackground(Color.clear)
		.listRowSeparator(.hidden)

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

	func recognizedView(_ item: ScanRecognizedItem) -> some View {
		var result = ""
		if !item.isBarcode {
			result = item.transcript ?? "empty"
		}
		return Text(result)
			.contextMenu {
				Button {
					UIPasteboard.general.setValue(item.transcript!,
								forPasteboardType: UTType.plainText.identifier)
				} label: {
					Label("Copy text", systemImage: "doc.on.doc")
				}
			}
	}
	
	var ocrButton: some View {
		Button { performOcr() } label: {
			Label("Detect text", systemImage: "text.viewfinder")
		}
		.padding(.top)
	}
	
	var footer: some View {
		HStack {
			Spacer()
			
			Text("Captured on " + (capture.timestamp?.formatted() ?? ""))
				.font(.caption)
		}
	}
	
	func presentImage() {
		imagePresented = true
	}
	
	func performOcr() {
		ocrActive = true
		guard let data = capture.image else { return }
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

struct CaptureSummary_Previews: PreviewProvider {
    static var previews: some View {
		let capture = ScanCapture(entity: ScanCapture.entity(), insertInto: nil)
		capture.id = UUID()
		capture.timestamp = Date()
		capture.image = UIImage(named: "scannerlive-logo")?.pngData()
//		let item = ScanRecognizedItem(entity: ScanRecognizedItem.entity(), insertInto: nil)
//		item.transcript = "Text from OCR"
//		capture.addToRecognizedItems(item)
		
		return CaptureSummary(capture: capture)
    }
}

//
//  ScannerViewController.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import UIKit
import VisionKit

struct ScannerViewController: UIViewControllerRepresentable {
	
	@ObservedObject var scan: Scan
	
	@Binding var startScanning: Bool
	@Binding var createNewCapture: Bool
	@Binding var autoCapture: Bool
	@Binding var lastCollectionOn: Date
	@State var viewSize: CGSize
	
	@State var onlyBarcodes: Bool = false
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	func makeUIViewController(context: Context) -> DataScannerViewController {
		
		// Create DataScanner
		let viewController = DataScannerViewController(
			recognizedDataTypes: getRecognizedDataTypes,
			qualityLevel: .accurate,
			recognizesMultipleItems: true,
			isHighFrameRateTrackingEnabled: false,
			isPinchToZoomEnabled: true,
			isHighlightingEnabled: true)
		
		// Wire up the coordinator
		viewController.delegate = context.coordinator
		
		let aspect = 8.5 / 11
		let rect = CGRect(origin: CGPoint(x: 0, y: viewSize.height), size: CGSize(width: viewSize.width, height: viewSize.width / aspect))
		
		// Inject DataScanner into the coordinator
		context.coordinator.viewController = viewController
		
		return viewController
	}
	
	func updateUIViewController(_ viewController: DataScannerViewController, context: Context) {
		
		if startScanning && !viewController.isScanning {
			
			try? viewController.startScanning()
			
			if autoCapture || firstScanHasNoPhoto {
				// Create CoreData object on scan start
				if createCaptureObject() != nil {
					
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
						captureImage(viewController: viewController)
					}
				}
			}
		}
		else if createNewCapture {
			Task {
				createNewCapture = false
				context.coordinator.createNewCapture()
			}
		}
		else if !startScanning && viewController.isScanning {
			viewController.stopScanning()
		}
	}
	
	var lastCapture: ScanCapture? {
		scan.capturesArray.last
	}
	
	var firstScanHasNoPhoto: Bool {
		if let scan = scan.capturesArray.first {
			return scan.imageData == nil
		}
		return true
	}
	
	func captureImage(viewController: DataScannerViewController) {
		Task {
			if let image = try? await viewController.capturePhoto() {
				// Assign lowres version to scanCapture
				if let capture = lastCapture {
					capture.createImage(fullSizedImage: image)
					capture.createThumbnail(fullSizedImage: image)
				}
			}
		}
	}
	
	func createCaptureObject() -> ScanCapture? {
		if let viewContext = scan.managedObjectContext {
			let capture = ScanCapture(context: viewContext)
			
			capture.id = UUID()
			capture.timestamp = Date()
			capture.order = Int32(scan.captures?.count ?? 0)
			
			self.scan.addToCaptures(capture)
			return capture
		}
		return nil
	}
	
	var getRecognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> {
		return [
			.text(languages: ["en"]),
			//			.text(textContentType: .dateTimeDuration),
			//			.text(textContentType: .URL),
			//			.text(textContentType: .emailAddress),
			//			.text(textContentType: .fullStreetAddress),
			//			.text(textContentType: .telephoneNumber),
				.barcode()]
	}
	
	class Coordinator: NSObject, DataScannerViewControllerDelegate {
		
		weak var viewController: DataScannerViewController?
		var parent: ScannerViewController
		
		// If no new words are detected for this many seconds, then next time
		// detection occurs it will be assigned to new ScanCapture
		let secondsSinceCapture: TimeInterval = 1.5
		
		// Once new words are detected, wait this many seconds before
		// photo capture is taken (to avoid motion between captures)
		let autoPhotoCaptureAfterSeconds: TimeInterval = 1.5
		
		// Store last captured photo timestamp, as to avoid quick multiple captures
		var photoLastCaptured = Date()
		let photoCaptureCooldownSeconds: TimeInterval = 2
		
		// Auto capture is scheduled, don't schedule another one until this one is done
		var autoCaptureInProgress = false
		
		init(_ parent: ScannerViewController) {
			self.parent = parent
		}
		
		
		// For each new item, create a new highlight view and add it to the view hierarchy.
		func dataScanner(_ dataScanner: DataScannerViewController, didAdd addItems: [RecognizedItem], allItems: [RecognizedItem]) {
			for item in addItems {
				
				addItem(item)
			}
		}
		
		func addItem(_ item: RecognizedItem) {
			
			guard let capture = parent.lastCapture else { return }
			
			var found = false
			
			for recognized in capture.recognizedItemsArray {
				if recognized.id == item.id {
					found = true
				}
				switch item {
				case .text(let itemText):
					if !recognized.isBarcode {
						if isTextSimilar(str1: recognized.transcript ?? "", str2: itemText.transcript) {
							found = true
						}
					}
				case .barcode(let itemText):
					if recognized.isBarcode {
						if recognized.transcript?.lowercased() == itemText.payloadStringValue?.lowercased() {
							found = true
						}
					}
				default:
					break
				}
			}
			
			if found {
				// Object already added, skip it
				
				print("Item skipped")
				return
			} else {
				print("Item unrecognized, add it")
			}
			
			// Item can be added, proceed
			if let viewContext = parent.scan.managedObjectContext {
				
				// Any new items within last x seconds? If yes, do not trigger camera auto capture
				var triggerCapture = !capture.recognizedItemsArray.isEmpty
				for item in capture.recognizedItemsArray {
					if item.timestamp?.addingTimeInterval(secondsSinceCapture) ?? Date() > Date() {
						triggerCapture = false
						break
					}
				}
				if photoLastCaptured.addingTimeInterval(secondsSinceCapture) > Date() {
					triggerCapture = false
				}
				
				// Create the new item
				let scanItem = ScanRecognizedItem(context: viewContext)
				scanItem.id = UUID()
				scanItem.timestamp = Date()
				switch item {
				case .text(let text):
					scanItem.isBarcode = false
					scanItem.transcript = text.transcript
				case .barcode(let barcode):
					scanItem.isBarcode = true
					let text = barcode.payloadStringValue
					scanItem.transcript = text
				default:
					break
				}
				capture.addToRecognizedItems(scanItem)
				
				// Set the time of this collection
				parent.lastCollectionOn = Date()
				
				if triggerCapture && !autoCaptureInProgress && parent.autoCapture {
					autoCaptureInProgress = true
					DispatchQueue.main.asyncAfter(deadline: .now() + autoPhotoCaptureAfterSeconds) {
						self.autoCaptureInProgress = false
						
						// Avoid the photo capture cooldown period
						if self.photoLastCaptured.addingTimeInterval(self.photoCaptureCooldownSeconds) < Date() {
							if let viewController = self.viewController {
								if viewController.isScanning {
									self.createNewCapture()
								}
							}
						}
					}
				}
				
			}
		}
		
		func createNewCapture() {
			
			photoLastCaptured = Date()
			
			// Move recent captures to the new capture
			var recentItems = [ScanRecognizedItem]()
			if let lastCapture = parent.lastCapture {
				for item in lastCapture.recognizedItemsArray {
					if item.timestamp?.addingTimeInterval(secondsSinceCapture + autoPhotoCaptureAfterSeconds) ?? Date() > Date() {
						recentItems.append(item)
					}
				}
			}
			
			if let newCapture = parent.createCaptureObject() {
				
				// Add previous captures, if found
				for item in recentItems {
					newCapture.addToRecognizedItems(item)
					item.parent = newCapture
				}
				
				// Take a photo for the new capture
				if let viewController = self.viewController {
					self.parent.captureImage(viewController: viewController)
				}
			}
			
		}
		
		func isTextSimilar(str1: String, str2: String) -> Bool {
			if str1.length <= 1 || str2.length <= 1 {
				return true
			}
			if str1.compare(str2, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
				// Simple comparison shows a duplicate (save time)
				return true
			}
			else {
				let score = str1.jaroWinkler(str2)
				let threshold = 0.85
				return score > threshold
			}
		}
		
		func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
			print(error)
		}
		
	}
}

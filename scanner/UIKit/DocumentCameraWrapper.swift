//
//  DocumentCameraWrapper.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import Foundation
import SwiftUI
import Vision
import VisionKit

final class CameraScanViewModel: NSObject, ObservableObject {
	@Published var errorMessage: String?
	@Published var imageArray: [UIImage] = []
	@Published var scan: Scan?
	
	func getDocumentCameraViewController() -> VNDocumentCameraViewController {
		let vc = VNDocumentCameraViewController()
		vc.delegate = self
		return vc
	}
	
	func removeImage(image: UIImage) {
		imageArray.removeAll{$0 == image}
	}
}


extension CameraScanViewModel: VNDocumentCameraViewControllerDelegate {
	
	func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
		controller.dismiss(animated: true, completion: nil)
	}
	
	func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
		errorMessage = error.localizedDescription
	}
	
	func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
		let viewContext = PersistenceController.shared.container.viewContext
		self.scan = Scan(context: viewContext)
		self.scan!.createDefaults()
		for i in 0..<scan.pageCount {
			let capture = ScanCapture(context: viewContext)
			capture.id = UUID()
			capture.timestamp = Date()
			capture.order = Int32(i)
			let image = scan.imageOfPage(at:i)
			capture.createImage(fullSizedImage: image)
			capture.createThumbnail(fullSizedImage: image)
			let captureOcr = CaptureOcr(scan: self.scan!, capture: capture, image: image, setScanTitle: i == 0)
			captureOcr.performOcr()
			self.scan!.addToCaptures(capture)
		}
		saveContext()
		AppState.shared.requestReviewIfNecessary()
		controller.dismiss(animated: true, completion: nil)
	}
	
	func saveContext() {
		let viewContext = PersistenceController.shared.container.viewContext
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

struct CaptureOcr {
	
	var scan: Scan
	var capture: ScanCapture
	var image: UIImage
	@State var setScanTitle: Bool = false
	
	func performOcr() {
		
		// Get the CGImage on which to perform requests.
		guard let cgImage = image.cgImage else { return }
		
		// Create a new image-request handler.
		let requestHandler = VNImageRequestHandler(cgImage: cgImage)
		
		// Create a new request to recognize text.
		let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
		
		request.recognitionLevel = .accurate
		
		request.automaticallyDetectsLanguage = true
		request.revision = VNRecognizeTextRequestRevision3
		
		request.usesLanguageCorrection = true
		
		print("#OCR: VNRecognizeTextRequestRevision: \(request.revision)")
		
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
		saveContext()
	}
	
	func processOcrResults(_ found: [String]) {
		let viewContext = PersistenceController.shared.container.viewContext
		for text in found {
			let item = ScanRecognizedItem(context: viewContext)
			item.id = UUID()
			item.order = Int32(capture.recognizedItemsArray.count)
			item.timestamp = Date()
			item.transcript = text
			capture.addToRecognizedItems(item)
		}
	}
	
	func saveContext() {
		if setScanTitle {
			if let title = capture.recognizedItemsArray.first?.transcript?.whitespaceCondensed().truncate(to: 50) {
				scan.title = title
			}
		}
		
		let viewContext = PersistenceController.shared.container.viewContext
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

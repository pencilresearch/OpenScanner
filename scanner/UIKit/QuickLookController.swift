//
//  QuickLookController.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import UIKit
import QuickLook

struct QuickLookView: View {
	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	@State var scanCapture: ScanCapture
	
	var body: some View {
		ZStack(alignment: .top) {
			QuickLookController(scanCapture: scanCapture)
				.navigationBarHidden(true)
				.ignoresSafeArea(edges: .all)
			
			HStack {

				buttonBack
				Spacer()
			}
			.padding(.horizontal)
			.padding(.top, 6)
		}
	}
	
	var buttonBack: some View {
		Button {
			presentationMode.wrappedValue.dismiss()
		} label: {
			HStack {
				Image(systemName: "chevron.left")
					.font(.title2)
				Text("Back")
			}
		}
	}
	
}

struct QuickLookController: UIViewControllerRepresentable {
	
	var scanCapture: ScanCapture
	
	func makeUIViewController(context: Context) -> UINavigationController {
		let controller = QLPreviewController()
		controller.dataSource = context.coordinator
		controller.delegate = context.coordinator
		controller.setEditing(true, animated: true)
		let navigationController = UINavigationController(rootViewController: controller)
		return navigationController
	}
	
	func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(parent: self)
	}
	
	class Coordinator: NSObject, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
		
		let parent: QuickLookController
		
		init(parent: QuickLookController) {
			self.parent = parent
		}
		
		func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
		
		func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode { .updateContents }
		
		func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
			
			var url: URL? = nil
			let data: Data = self.parent.scanCapture.imageData ?? Data()
			url = imageUrl
			do {
				try data.write(to: url!)
			} catch {
				print("Error loading image")
			}
			
			let previewItem = ScanPreview(url: url, title: "Scan")
			return previewItem as QLPreviewItem
		}
		
		func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
			
			do {
				let imageData = try Data(contentsOf: imageUrl)
				parent.scanCapture.imageData = imageData
				parent.scanCapture.parent?.lastUpdate = Date()
				parent.scanCapture.createThumbnail()
				saveContext()
			} catch {
				print("Error loading modified image")
			}
		}
		
		var imageUrl: URL {
			getDocumentsDirectory().appendingPathComponent((self.parent.scanCapture.id?.uuidString ?? "scan") + ".jpg")
		}
		
		func saveContext() {
			let viewContext = PersistenceController.shared.container.viewContext
			if viewContext.hasChanges {
				do {
					try viewContext.save()
				} catch {
					let nserror = error as NSError
					print("Error saving context: \(nserror)")
				}
			}
		}
	}
}

class ScanPreview: NSObject, QLPreviewItem {
	
	var previewItemURL: URL?
	var previewItemTitle: String?
	
	init(url: URL?, title: String?) {
		previewItemURL = url
		previewItemTitle = title
	}
}

//
//  PageScan.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import Vision
import VisionKit

struct PageScan: View {
	@Environment(\.managedObjectContext) private var viewContext
	
	@ObservedObject var viewModel = CameraScanViewModel()
	
	@State var documentTitle: String = "Document"
	@State var showScanOnInit = true
	
	@State var isEditMode: EditMode = .active
	
	@State var scan: Scan?
	
	var body: some View {
		ZStack {
		}
		.onAppear {
			if showScanOnInit {
				showScanOnInit = false
				startScan()
			} else {
				AppState.shared.viewState = .Home
			}
			
		}
	}
	
	func startScan() {
		UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController?.present(
			viewModel.getDocumentCameraViewController(),
			animated: true,
			completion: {
				print("Scan started.")
			})
	}
	
	func moveItems(from source: IndexSet, to destination: Int) {
		viewModel.imageArray.move(fromOffsets: source, toOffset: destination)
	}
	
	private func deleteItems(offsets: IndexSet) {
		withAnimation {
			viewModel.imageArray.remove(atOffsets: offsets)
		}
	}
}

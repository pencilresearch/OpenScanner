//
//  LiveCaptureOverlay.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import QuickLook
import AVFoundation

struct LiveCaptureOverlay: View {

	@Environment(\.managedObjectContext) private var viewContext
	
	@ObservedObject var capture: ScanCapture
	let scrollValue: ScrollViewProxy
	
	@Binding var selectedRecognizedItem: ScanRecognizedItem?
	@State var editing = false
	
	var body: some View {
		ZStack(alignment: .topTrailing) {
			
			// Spread the view horizontally
			Color.clear
		
			// Show captured text
			HStack(alignment: .top) {
				SmallThumbnail(image: capture.thumbnail)
					.flippedUpsideDown()

				LazyVStack(alignment: .leading, spacing: 0) {
					Rectangle()
						.fill(.clear)
						.frame(height: 1)
					
					ForEach (capture.recognizedItemsArray.reversed(), id: \.self) { item in
						RecognizedItemView(item: item, readOnly: true, showingMenuFor: $selectedRecognizedItem, editing: $editing)
							.flippedUpsideDown()
							.padding(.vertical, 4)
							.padding(.leading, 8)
							.opacity(selectedRecognizedItem != nil && selectedRecognizedItem != item ? 0.5 : 1)
							.contentShape(Rectangle())
							.id(item.id)
							.onTapGesture {
								if selectedRecognizedItem == item {
									selectedRecognizedItem = nil
								} else {
									selectedRecognizedItem = item
								}
							}
					}
					
				}
				.padding(.horizontal, 8)
			}
		}
		.animation(.default, value: capture.recognizedItemsArray.count)
		.animation(.default, value: selectedRecognizedItem)
	}
	
	
	func shareItem(item: ScanRecognizedItem) {
		if let url = item.textUrl {
			let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
		}
	}
	
}

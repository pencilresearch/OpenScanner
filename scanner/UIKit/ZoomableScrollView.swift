//
//  ZoomableScrollView.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import Foundation

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
	private var content: Content
	
	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}
	
	func makeUIView(context: Context) -> UIScrollView {
		// set up the UIScrollView
		let scrollView = UIScrollView()
		scrollView.delegate = context.coordinator
		scrollView.maximumZoomScale = 20
		scrollView.minimumZoomScale = 1
		scrollView.bouncesZoom = true
		
		// create a UIHostingController to hold our SwiftUI content
		let hostedView = context.coordinator.hostingController.view!
		hostedView.translatesAutoresizingMaskIntoConstraints = true
		hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		hostedView.frame = scrollView.bounds
		hostedView.backgroundColor = UIColor.clear
		scrollView.addSubview(hostedView)
		
		return scrollView
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(hostingController: UIHostingController(rootView: self.content))
	}
	
	func updateUIView(_ uiView: UIScrollView, context: Context) {
		// update the hosting controller's SwiftUI content
		context.coordinator.hostingController.rootView = self.content
		assert(context.coordinator.hostingController.view.superview == uiView)
	}
	
	// MARK: - Coordinator
	
	class Coordinator: NSObject, UIScrollViewDelegate {
		var hostingController: UIHostingController<Content>
		
		init(hostingController: UIHostingController<Content>) {
			self.hostingController = hostingController
		}
		
		func viewForZooming(in scrollView: UIScrollView) -> UIView? {
			return hostingController.view
		}
	}
}

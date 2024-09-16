//
//  ContentView.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import CoreData

struct ContentView: View {
	@Environment(\.managedObjectContext) private var viewContext
	@StateObject var loading = AppState.shared
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \Scan.order, ascending: false)],
		animation: .default)
	private var scans: FetchedResults<Scan>
	
	@State private var backgroundGradient = LinearGradient(
		colors: [
			Color(hex: 0xcfd9df),
			Color(hex: 0xe2ebf0)],
		startPoint: .topLeading,
		endPoint: .bottomTrailing)
	
	@State private var lightGradient = LinearGradient(
		colors: [
			Color(hex: 0xebedee),
			Color(hex: 0xfdfbfb)],
		startPoint: .topLeading,
		endPoint: .bottomTrailing)
	
	@State private var darkGradient = LinearGradient(
		colors: [
			Color(hex: 0x485563),
			Color(hex: 0x29323c)],
		startPoint: .topLeading,
		endPoint: .bottomTrailing)
	
	@State private var transparentGradient =
	LinearGradient(
		colors: [
			Color(hex: 0x9999bb).opacity(0.2),
			Color(hex: 0x777799).opacity(0.2)],
		startPoint: .topLeading,
		endPoint: .bottomTrailing)
	
	var body: some View {
		
		NavigationView {
			
			ZStack(alignment: .center) {
				
				switch AppState.shared.viewState {
				case .Home, .About:
					if let scan = AppState.shared.openScan {
						// Open a scan linked from the outside
						LiveScanSummary(scan: scan)
					} else {
						// Open standard Home screen
						HomeView()
							.transition(.move(edge: .bottom))
					}
				case .Page:
					PageScan()
						.transition(.opacity)
				}
				
				if AppState.shared.viewState == .About {
					Color.black.opacity(0.2)
						.transition(.opacity)
						.ignoresSafeArea(.all)
						.onTapGesture {
							withAnimation {
								AppState.shared.viewState = .Home
							}
						}
					AboutView()
						.zIndex(1)
						.transition(.opacity)
				}
				
			}
			
			.navigationTitle("Scans")
			.navigationBarTitleDisplayMode(.automatic)
			.background(DefaultBackgroundGradient,
						ignoresSafeAreaEdges: [.all]
			)
		}
		.onAppear {
			ScannerShortcuts.updateAppShortcutParameters()
		}
	}
	
	
}


struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
	}
}

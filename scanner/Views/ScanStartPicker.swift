//
//  ScanStartPicker.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI

struct ScanStartPicker: View {
	
	@State private var bottomBarExpanded = false
	
	@State private var darkLinearGradient = LinearGradient(
		colors: [
			Color(hex: 0x868f96),
			Color(hex: 0x596164)],
		startPoint: .bottomLeading,
		endPoint: .topTrailing)
	
	@State private var lightLinearGradient = LinearGradient(
		colors: [
			Color(hex: 0xf9eef8),
			Color(hex: 0xfbfcfb)],
		startPoint: .bottomLeading,
		endPoint: .topTrailing)
	
	var body: some View {
		VStack {
			
			if bottomBarExpanded {
				Button { switchView(.Page) } label: {
					TransparentTaskButton(caption: "Scan", image: "doc.viewfinder", blackForeground: true)
				}
				.padding(.vertical)
				.transition(.scale)
				.accessibilityLabel("Start a scan")
			}
			
			Button { switchView(.Page) } label: {
				ZStack {
					Image(systemName: "plus.viewfinder")
						.symbolRenderingMode(.palette)
						.foregroundStyle(Color.black, Color.yellow)
						.font(.system(size: 40, weight: .light))
						.padding(16)
				}
			}
			.accessibilityLabel("Start scanning")
			
		}
		.background(
			ZStack {
				Capsule()
					.fill(
						Color.white
							.shadow(.inner(color: Color.black.opacity(0.1), radius: 10))
					)
				Capsule()
					.stroke(Color.gray, lineWidth: 1)
			}
		)
		.clipShape(Capsule())
	}
	
	func switchView(_ viewState: ViewState) {
		withAnimation(.easeInOut) {
			AppState.shared.viewState = viewState
		}
	}
	
}

struct ScanStartPicker_Previews: PreviewProvider {
	static var previews: some View {
		ScanStartPicker()
	}
}

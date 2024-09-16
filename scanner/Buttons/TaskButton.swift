//
//  TaskButton.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI

struct TaskButton: View {
	
	@State var caption: String = ""
	@State var image: String = ""
	
	var body: some View {
		
		
		ZStack {
			RoundedRectangle(cornerRadius: 16, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							Color(hex: 0x868f96),
							Color(hex: 0x596164)],
						startPoint: .bottomLeading,
						endPoint: .topTrailing)
				)
			
			VStack(spacing: 8) {
				Image(systemName: image)
					.resizable()
					.scaledToFit()
					.padding(4)
					.frame(maxHeight: .infinity)
					.frame(width: 50)
				
				Text(caption)
					.font(.caption)
					.lineLimit(1)
			}
			.padding(8)
		}
		.foregroundColor(Color.white)
		.frame(width: 100, height: 80)
		.shadow(radius: 3)
	}
}

struct TransparentTaskButton: View {
	
	@State var caption: String = ""
	@State var image: String = ""
	@State var multicolor: Bool = false
	@State var blackForeground: Bool = false
	
	var body: some View {
		
		
		ZStack {
			
			VStack(spacing: 4) {
				Image(systemName: image)
					.symbolRenderingMode(.palette)
					.foregroundStyle(blackForeground ? Color.black : Color.primary, multicolor ? Color.yellow : blackForeground ? Color.black : Color.primary)
					.font(.system(size: 40, weight: .light))
					.frame(maxHeight: .infinity)
					.frame(width: 50)
				
				if caption != "" {
					Text(caption)
						.font(.system(size: 14))
						.lineLimit(1)
				}
			}
			.padding(8)
		}
		.foregroundColor(Color.black)
		.frame(width: caption == "" ? nil : 80, height: caption == "" ? nil : 80)
	}
}


struct TaskToggleButton: View {
	
	@State var caption: String = ""
	@State var image: String = ""
	
	@Binding var active: Bool
	
	var body: some View {
		
		
		ZStack {
			
			VStack(spacing: 8) {
				Image(systemName: image)
					.symbolRenderingMode(.palette)
					.foregroundStyle(Color.black, active ? Color.yellow.opacity(0) : Color.yellow)
					.font(.system(size: 40, weight: .light))
					.frame(maxHeight: .infinity)
					.frame(width: 50)
				
				if caption != "" {
					Text(caption)
						.font(.caption)
						.lineLimit(1)
				}
			}
			.padding(8)
		}
		.foregroundColor(Color.black)
		.frame(width: 80, height: 80)
	}
}

struct TransparentTaskButton_Previews: PreviewProvider {
	static var previews: some View {
		TaskButton(caption: "Classic", image: "plus.viewfinder")
	}
}

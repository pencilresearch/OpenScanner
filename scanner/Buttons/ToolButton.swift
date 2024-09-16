//
//  ToolButton.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI

struct ToolButton: View {
	
	var text: String = ""
	var image: String = ""
	
	var body: some View {
		HStack {
			if image != "" {
				Image(systemName: image)
			}
			if text != "" {
				Text(text)
			}
		}
		.font(.title3)
		.foregroundColor(Color.primary)
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
		.frame(height: 36)
		.background(
			Capsule()
				.fill(Color.background)
				.shadow(radius: 2)
		)
	}
}

struct ToolButton_Previews: PreviewProvider {
	static var previews: some View {
		ToolButton(text: "Save")
	}
}

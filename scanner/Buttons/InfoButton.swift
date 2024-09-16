//
//  InfoButton.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI

struct InfoButton: View {
	
	@State var caption: String = ""
	@State var image: String = ""
	
	var body: some View {
		VStack(spacing: 8) {
			Image(systemName: image)
				.resizable()
				.scaledToFit()
				.frame(maxHeight: .infinity)
				.frame(width: 50)
			
			if caption != "" {
				Text(caption)
					.font(.caption)
					.lineLimit(1)
			}
		}
		.padding(8)
		.foregroundColor(Color.primary)
		.frame(width: 60, height: 60)
		.shadow(radius: 9)
	}
}

struct InfoButton_Previews: PreviewProvider {
	static var previews: some View {
		InfoButton(caption: "About", image: "info")
	}
}

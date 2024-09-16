//
//  ViewExtensions.swift
//  scanner
//
//  Created by Slaven Radic on 2022-07-25.
//

import Foundation
import SwiftUI

public extension Color {
	
	static let background = Color("background")
	static let foreground = Color("foreground")
	static let accent = Color("accent")

	
	init(hex: UInt, alpha: Double = 1) {
		self.init(
			.sRGB,
			red: Double((hex >> 16) & 0xff) / 255,
			green: Double((hex >> 08) & 0xff) / 255,
			blue: Double((hex >> 00) & 0xff) / 255,
			opacity: alpha
		)
	}
}

struct SmallThumbnail: View {
	
	var image: UIImage?
	var size: CGSize = CGSize(width: 80, height: 80)
	
	var body: some View {
		ZStack {
			if image != nil {
				Image(uiImage: image ?? UIImage())
					.resizable()
					.aspectRatio(1.0, contentMode: .fit)
					.clipShape(RoundedRectangle(cornerRadius: 8))
				
			} else {
				Image(systemName: "viewfinder")
					.font(.system(size: size.width * 0.5, weight: .ultraLight))
			}
			RoundedRectangle(cornerRadius: 8)
				.stroke(Color.background, lineWidth: 2)
		}
		.foregroundColor(Color.primary)
		.frame(width: size.width, height: size.height)
	}
}

func getDocumentsDirectory() -> URL {
	let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
	return paths[0]
}

func getTemporaryDirectory() -> URL {
	let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent("Document")
	return previewURL
}

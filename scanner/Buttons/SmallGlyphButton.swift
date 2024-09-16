//
//  SmallGlyphButton.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI

struct SmallGlyphButton: View {
	
	var systemImage: String
	var destructive: Bool = false
	
	var body: some View {
		ZStack {
			Circle()
				.foregroundColor(Color.white)
			Circle()
				.foregroundColor(destructive ? Color.red : Color.black)
				.padding(2)
			Image(systemName: systemImage)
				.font(.system(size: 16))
				.foregroundColor(Color.white)
				.padding(2)
		}
		.frame(width: 32, height: 32)
	}
}

struct SmallGlyphButton_Previews: PreviewProvider {
	static var previews: some View {
		SmallGlyphButton(systemImage: "doc")
	}
}


struct SmallThumbnail: View {
	
	var image: UIImage?
	var size: CGSize = CGSize(width: 80, height: 80)
	var borderColor: Color = Color.background
	
	var body: some View {
		ZStack {
			if image != nil {
				Image(uiImage: image ?? UIImage())
					.resizable()
					.scaledToFill()
					.frame(width: size.width, height: size.height)
					.clipShape(RoundedRectangle(cornerRadius: 8))
				
			}
			RoundedRectangle(cornerRadius: 8)
				.stroke(borderColor, lineWidth: 2)
		}
		.foregroundColor(Color.primary)
		.padding(2)
		.frame(width: size.width, height: size.height)
	}
}

struct CaptureThumbnail: View {
	
	@State var capture: ScanCapture?
	
	// Letter-sized page aspect ratio
	@State var aspectRatio = 0.77
	
	var body: some View {
		ZStack {
			
			if image != nil {
				Image(uiImage: image ?? UIImage())
					.resizable()
					.scaledToFill()
					.frame(width: rotate ? height : height * aspectRatio, height: rotate ? height * aspectRatio : height)
					.clipShape(RoundedRectangle(cornerRadius: 4))
					.rotationEffect(Angle(degrees: rotate ? -90 : 0))
			} else {
				RoundedRectangle(cornerRadius: 4)
					.fill(Color.gray)
					.opacity(0.1)
			}
		}
		.frame(width: height * aspectRatio, height: height)
		.foregroundColor(Color.primary)
		.overlay(
			RoundedRectangle(cornerRadius: 4)
				.stroke(image != nil ? Color.white : Color.clear, lineWidth: 1)
		)
		.frame(height: height)
		.shadow(radius: 6)
	}
	
	var height: CGFloat {
		return 100
	}
	
	var rotate: Bool {
		guard let image = image else { return false }
		
		return image.size.width > image.size.height
	}
	
	var image: UIImage? {
		if let capture = capture {
			return capture.thumbnail
		} else {
			return nil
		}
	}
}

struct FlexyThumbnail: View {
	
	var image: UIImage?
	var borderColor: Color = Color.background
	
	var body: some View {
		ZStack {
			Color.clear
			
			if image != nil {
				Image(uiImage: image ?? UIImage())
					.resizable()
					.scaledToFill()
					.clipShape(RoundedRectangle(cornerRadius: 8))
				
			}
			RoundedRectangle(cornerRadius: 8)
				.stroke(borderColor, lineWidth: 2)
		}
		.foregroundColor(Color.primary)
		.padding(8)
	}
}

struct SmallThumbnail_Previews: PreviewProvider {
	static var previews: some View {
		SmallThumbnail(image: nil)
	}
}

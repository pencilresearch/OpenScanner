//
//  OpenScannerButton.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI

struct OpenScannerButton: View {
	
	@State var caption: String = ""
	@State var image: String = ""
	var size: ContentSizeCategory = .small
	var exactHeight: CGFloat = 0
	var outline: Bool = true
	@Binding var justAppeared: Bool
	
	var height: CGFloat
	{
		if exactHeight > 0 {
			return exactHeight
		} else {
			
			switch size {
			case .small:
				return 60
			case .medium:
				return 100
			case .large:
				return 140
			default:
				return 100
			}
		}
	}
	
	var body: some View {
		
		return GeometryReader { geometry in
			
			ZStack {
				Color.clear
				
				if geometry.size.width >= geometry.size.height {
					Text(caption)
						.font(.custom(
							"Futura",
							fixedSize: geometry.size.height * 0.25))
						.foregroundColor(.primary)
						.bold()
					if image != "" {
						Image(systemName: image)
							.resizable()
							.scaledToFit()
							.padding(24)
							.foregroundColor(.white)
					}
				}
			}
			.overlay {
				ZStack {
					HStack {
						Image(systemName: "viewfinder")
							.resizable()
							.scaledToFill()
							.foregroundColor(Color.yellow)
							.frame(width: geometry.size.height / 2, alignment: .leading)
							.clipped()
						
						Spacer()
						
					}
					HStack {
						Spacer()
						
						Image(systemName: "viewfinder")
							.resizable()
							.scaledToFill()
							.foregroundColor(Color.yellow)
							.frame(width: geometry.size.height / 2, alignment: .trailing)
							.clipped()
					}
				}
				.padding(.horizontal, justAppeared ? -30 : 0)
				.padding(geometry.size.height * 0.1)
				.rotationEffect(Angle(degrees: justAppeared ? 145 : 0))
			}
			.frame(width: geometry.size.width, height: geometry.size.height)
			.clipShape(RoundedRectangle(cornerRadius: geometry.size.height * 0.2))
			.overlay(RoundedRectangle(cornerRadius: geometry.size.height * 0.2).stroke(Color.primary, lineWidth: outline ? 1 : 0))
		}
		.frame(height: height)
		.animation(.bouncy(duration: 0.5).delay(0.5), value: justAppeared)
	}
}

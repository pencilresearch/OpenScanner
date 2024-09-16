//
//  WidgetView.swift
//  ScannerWidgetExtension
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import WidgetKit

struct ScannerWidgetEntryView: View {
	
	@Environment(\.widgetFamily) var widgetFamily

	var entry: Provider.Entry
	var viewState: ViewState
	
	var body: some View {
		switch widgetFamily {
		case .systemSmall:
			// Small home screen widget
			ZStack {
				DefaultBackgroundGradient
				buttonText(scaleBy: 2.5)
			}
		case .accessoryCircular:
			// Small circular lock screen widget
			ZStack {
				buttonText()
			}
		default:
			ZStack {
			}
		}
	}
	
	func buttonText(scaleBy: Double = 1) -> some View {
		ZStack {
			Text(caption)
				.font(.system(size: caption.count > 4 ? 10 * scaleBy : 15 * scaleBy))
				.bold()
			Image(systemName: "viewfinder")
				.font(.system(size: 42 * scaleBy))
		}
	}
	
	var caption: String {
		"Classic"
	}
	
}


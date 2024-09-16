//
//  AboutView.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI

struct AboutView: View {
	
	@State var justAppeared = true
	@State var showingRestoreError = false
	
	
	static let supportBody: String = "%0A%0A%0A----------%0APlease%20write%20your%20message%20above%20this%20section."
	
	var body: some View {
		ZStack {
			
			VStack(alignment: .leading) {
				HStack(spacing: 6) {
					ZStack {
						OpenScannerButton(caption: "OPEN", exactHeight: 80, justAppeared: $justAppeared)
							.frame(width: 80, height: 80)
					}
					
					ZStack(alignment: .leading) {
						Text("Scanner")
							.font(.custom(
								"AmericanTypewriter",
								fixedSize: 30))
						
						ZStack (alignment: .bottomLeading) {
							Color.clear
							Text("Scan, Save, Sync.")

						}
					}
					.frame(width: 180, height: 72)
				}
				.padding(.bottom)

				
				Text("✏️ Created by [Pencil Research](https://pencilresearch.com), home")
					.padding(.bottom, 2)
				Text("of [Penbook for iPad](https://penbook.app) and [Petey AI](https://petey.app).")
					.padding(.bottom)

				HStack {
					VStack(alignment: .leading, spacing: 30) {
						
						Button(action: {
							UIApplication.shared.open(URL(string: "mailto:support@openscanner.app?subject=Open%20Scanner%20support%20request&body=\(AboutView.supportBody)")!,
													  options: [:],
													  completionHandler: nil)
						}) {
							HStack {
								Image(systemName: "ellipsis.bubble")
								Text("Need help?")
							}
						}
						
						Text("Made in 🇨🇦 on unceded Lekwungen, Musqueam, Stó:lō, Squamish, and Tsleil-Waututh lands.")

						HStack(spacing: 0) {
							
							Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "•.•") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "•"))")
							// Legal links
							Text(" • [Privacy](https://openscanner.app/#privacy)")
							
						}
					}
				}
			}
			.font(.custom("AmericanTypewriter", fixedSize: 16))
		}
		.onAppear {
			withAnimation(.easeOut(duration: 0.5)) {
				justAppeared = false
			}
		}
		.padding()
		.ignoresSafeArea(.all)
	}
}

struct AboutView_Previews: PreviewProvider {
	static var previews: some View {
		AboutView()
	}
}

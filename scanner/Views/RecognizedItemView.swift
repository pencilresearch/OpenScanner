//
//  RecognizedItemView.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import SwiftUI
import QuickLook

struct RecognizedItemView: View {
	
	@Environment(\.managedObjectContext) private var viewContext
	
	var item: ScanRecognizedItem
	var readOnly: Bool = true
	@Binding var showingMenuFor: ScanRecognizedItem?
	@Binding var editing: Bool
	
	@State var transcript: String = ""
	@State var showMenu = false
	@FocusState var focused: Bool
	
	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			
			Color.clear
				.frame(height: 1)
			
			if !item.isBarcode {
				// Text item, show editor or viewer
				if editing && showingMenuFor == item {
					TextField("No text found", text: $transcript, axis: .vertical)
						.lineLimit(100)
						.focused($focused)
						.padding(.leading, 12)
						.background(
							ZStack(alignment: .leading) {
								Color.clear
								Capsule()
									.fill(showingMenuFor == item ? Color.accent : Color.yellow)
									.frame(width: 4)
							}
						)
						.onChange(of: transcript, perform: { changed in
							item.transcript = changed
						})
						.onChange(of: focused, perform: { changed in
							if !changed {
								self.editing = false
							}
						})
				} else if readOnly {
					// No tap handler used, as we need it for the overlay
					textEntry(item)
				} else {
					// Use tap handler to toggle editor
					textEntry(item)
						.onTapGesture {
							if !readOnly {
								if showingMenuFor == item {
									showingMenuFor = nil
								} else {
									showingMenuFor = item
								}
							}
						}
				}
				
				if item.urlAddress != nil {
					dataTagView(item.urlAddress, schema: "http://", image: "text.viewfinder")
				}
				
				if item.emailAddress != nil {
					dataTagView(item.emailAddress, schema: "mailto:", image: "person.fill.viewfinder")
				}
				
				if item.phoneNumber != nil {
					dataTagView(item.phoneNumber, schema: "tel://", image: "person.fill.viewfinder")
				}
				
				if item.mailingAddress != nil {
					dataTagView(item.mailingAddress, schema: "maps://?address=", image: "location.fill.viewfinder")
				}
				
			} else {
				// Barcode
				if item.transcript != nil {
					dataTagView(item.urlAddress, schema: "", image: "qrcode.viewfinder")
				}
			}
			
			
		}
		.onAppear {
			transcript = item.transcript ?? ""
		}
		.onChange(of: editing) { newValue in
			focused = newValue ? true : false
		}
	}
	
	func textEntry(_ item: ScanRecognizedItem) -> some View {
		Text(item.transcript ?? "")
			.padding(.leading, 12)
			.lineLimit(10)
			.foregroundColor(readOnly ? Color.white : Color.primary)
			.background(
				ZStack(alignment: .leading) {
					if showingMenuFor == item {
						Color.accent.opacity(0.075)
					} else {
						Color.clear
					}
					Capsule()
						.fill(showingMenuFor == item ? Color.accent : Color.yellow)
						.frame(width: 4)
				}
			)
	}
	
	func dataTagView(_ text: String?, schema: String, image: String) -> some View {
		
		return HStack {
			if let text = text {
				
				Image(systemName: image)
					.foregroundStyle(readOnly ? Color.white : Color.primary, showingMenuFor == item ? Color.blue : Color.yellow)
					.font(.system(size: 22))
				Text(try! AttributedString(
					markdown: markdownString(text, schema: schema),
					options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
				.dataTagModifier()
			}
		}
		.foregroundColor(readOnly ? Color.white : Color.primary)
		.padding(.top, 8)
	}
	
	func markdownString(_ text: String, schema: String) -> String {
		let title = "[" + text + "]"
		var encodedDestination = (text.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.urlFragmentAllowed)) ?? "").trimmingCharacters(in: .whitespaces)
		if schema.contains("http") {
			// Handle web links separately
			
			if !encodedDestination.starts(with: "http") {
				// Add schema, hope they forward http to https
				encodedDestination = schema + encodedDestination
			}
			let url =  "(" + encodedDestination + ")"
			return title + url
		} else {
			let url =  "(" + schema + encodedDestination + ")"
			return title + url
		}
	}
	
	
	func saveContext() {
		if viewContext.hasChanges {
			do {
				try viewContext.save()
			} catch {
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
}

struct SummaryContextButton: View {
	
	var caption: String = ""
	var image: String = ""
	@State var destructive: Bool = false
	@State var roundTop: Bool = false
	@State var roundBottom: Bool = false
	@State var gray: Bool = false
	
	var body: some View {
		HStack(spacing: 8) {
			
			Text(caption)
				.font(.system(size: 13))
				.foregroundColor(Color.primary)
			
			Image(systemName: image)
				.font(.system(size: 16))
				.foregroundColor(Color.white)
				.frame(width: 24)
				.padding(.vertical, 16)
				.padding(.horizontal, 2)
				.background(
					RoundedRectangle(cornerRadius: 8, style: .continuous)
						.fill(destructive ? Color.red : gray ? Color.gray : Color.accent)
						.padding(.top, roundTop ? 8 : -8)
						.padding(.bottom, roundBottom ? 8 : -8)
				)
			
		}
		.padding(4)
		.frame(height: 40)
		.clipped()
	}
}

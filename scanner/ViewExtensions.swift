//
//  ViewExtensions.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import Foundation
import SwiftUI
import LinkPresentation
import UIKit
import ImageIO

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

var DefaultBackgroundGradient: LinearGradient {
	LinearGradient(
		colors: [
			Color("gradientMainTop"),
			Color("gradientMainBottom")],
		startPoint: .topLeading,
		endPoint: .bottomTrailing)
	
}

func getDocumentsDirectory() -> URL {
	let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
	return paths[0]
}

func getTemporaryDirectory() -> URL {
	let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent("Document")
	return previewURL
}

class ShareImage: UIActivityItemProvider {
	var image: UIImage
	
	override var item: Any {
		get {
			return self.image
		}
	}
	
	override init(placeholderItem: Any) {
		guard let image = placeholderItem as? UIImage else {
			fatalError("Couldn't create image from provided item")
		}
		
		self.image = image
		super.init(placeholderItem: placeholderItem)
	}
	
	@available(iOS 13.0, *)
	override func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
		
		let metadata = LPLinkMetadata()
		metadata.title = "Result Image"
		
		var thumbnail: NSSecureCoding = NSNull()
		if let imageData = self.image.pngData() {
			thumbnail = NSData(data: imageData)
		}
		
		metadata.imageProvider = NSItemProvider(item: thumbnail, typeIdentifier: "public.png")
		
		return metadata
	}
	
}

extension Animation {
	func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation {
		if expression {
			return self.repeatForever(autoreverses: autoreverses)
		} else {
			return self
		}
	}
}

extension UIImage {
	
	var aspectRatio: CGFloat {
		size.width / size.height
	}
	
	func resizeToWidth(_ width: CGFloat) -> UIImage {
		
		// Determine the scale factor that preserves aspect ratio
		let ratio = size.width / size.height
		let height = width / ratio
		
		// Compute the new image size that preserves aspect ratio
		let scaledImageSize = CGSize(
			width: width,
			height: height
		)
		
		// Draw and return the resized UIImage
		
		let format = UIGraphicsImageRendererFormat()
		format.scale = 1
		
		let renderer = UIGraphicsImageRenderer(size: scaledImageSize, format: format)
		
		let scaledImage = renderer.image { _ in
			self.draw(in: CGRect(
				origin: .zero,
				size: scaledImageSize
			))
		}
		
		return scaledImage
	}
	
	func resize(newSize: CGSize) -> UIImage? {
		let renderer = UIGraphicsImageRenderer(size: newSize)
		return renderer.image { (context) in
			self.draw(in: CGRect(origin: .zero, size: newSize))
		}
	}
	
}

struct FlippedUpsideDown: ViewModifier {
	func body(content: Content) -> some View {
		content
			.rotationEffect(.radians(CGFloat.pi))
			.scaleEffect(x: -1, y: 1, anchor: .center)
	}
}
extension View {
	func flippedUpsideDown() -> some View{
		self.modifier(FlippedUpsideDown())
	}
}

extension String {
	func truncate(to limit: Int) -> String {
		if count > limit {
			let truncated = String(prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines)
			return truncated + "\u{2026}"
		} else {
			return self
		}
	}
	
	func sanitized() -> String {
		// see for ressoning on charachrer sets https://superuser.com/a/358861
		let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
			.union(.newlines)
			.union(.illegalCharacters)
			.union(.controlCharacters)
		
		return String(
			self
				.components(separatedBy: invalidCharacters)
				.joined(separator: "")
				.prefix(50)
		)
	}
	
	mutating func sanitize() -> Void {
		self = self.sanitized()
	}
	
	func whitespaceCondensed() -> String {
		return self.components(separatedBy: .whitespacesAndNewlines)
			.filter { !$0.isEmpty }
			.joined(separator: " ")
	}
	
	mutating func condenseWhitespace() -> Void {
		self = self.whitespaceCondensed()
	}
}

extension View {
	/// Applies the given transform if the given condition evaluates to `true`.
	/// - Parameters:
	///   - condition: The condition to evaluate.
	///   - transform: The transform to apply to the source `View`.
	/// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
	@ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
		if condition() {
			transform(self)
		} else {
			self
		}
	}
}

struct ToolbarBackgroundModifier: ViewModifier {
	var color: Color
	
	func body(content: Content) -> some View {
		content
			.toolbarBackground(color, for: .navigationBar)
	}
}

struct ScrollContentBackgroundHiddenModifier: ViewModifier {
	
	func body(content: Content) -> some View {
		content
			.scrollContentBackground(.hidden)
	}
}

struct ScrollDismissesKeyboardInteractivelyModifier: ViewModifier {
	
	func body(content: Content) -> some View {
		content
#if !os(xrOS)
			.scrollDismissesKeyboard(.interactively)
#endif
	}
}

extension View {
	
	@ViewBuilder
	func ios16toolbarBackground(_ color: Color) -> some View {
		self
			.modifier(ToolbarBackgroundModifier(color: color))
	}
	
	@ViewBuilder
	func ios16scrollContentBackground() -> some View {
		self
			.modifier(ScrollContentBackgroundHiddenModifier())
	}
	
	@ViewBuilder
	func iOSScrollDismissesKeyboard() -> some View {
		self
			.modifier(ScrollDismissesKeyboardInteractivelyModifier())
	}
	
	@ViewBuilder
	func dataTagModifier() -> some View {
		self
			.modifier(DataTagModifier())
	}
}

struct DataTagModifier: ViewModifier {
	
	func body(content: Content) -> some View {
		content
			.padding(.vertical, 4)
			.padding(.horizontal, 8)
			.font(.system(size: 13))
			.lineLimit(1)
			.background(Capsule().fill(Color.white))
		
	}
}

extension Date: RawRepresentable {
	private static let formatter = ISO8601DateFormatter()
	
	public var rawValue: String {
		Date.formatter.string(from: self)
	}
	
	public init?(rawValue: String) {
		self = Date.formatter.date(from: rawValue) ?? Date()
	}
}

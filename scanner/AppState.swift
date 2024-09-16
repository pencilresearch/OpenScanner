//
//  AppState.swift
//  Open Scanner
//
//  Created by Slaven Radic on 2024-09-01.
//

import Foundation
import AppIntents
import CoreData
import AVFoundation
import CoreLocation
#if canImport(CoreLocationUI)
import CoreLocationUI
#endif
import StoreKit
import SwiftUI

enum ViewState: String {
	case Home, Page, About
}

extension ViewState: AppEnum {
	static var typeDisplayRepresentation: TypeDisplayRepresentation = "Scanner mode"

	static var caseDisplayRepresentations: [ViewState: DisplayRepresentation] = [
		.Home: "Scan List",
		.Page: "Scan Now",
		.About: "About Open Scanner",
	]
}

class AppState: ObservableObject {
	
	public static let shared = AppState()
	var locationManager = LocationManager()
	
	@Published var viewState = ViewState.Home {
		didSet {
			stopSpeaking()
		}
	}
	
	@AppStorage("lastReviewPrompt") private var lastReviewPrompt: Date = Date().addingTimeInterval(TimeInterval(-365*24*60*60))

	@Published var openScan: Scan?
	@Published var openRecognizedItem: ScanRecognizedItem?
	
	private let speechSynthesizer = AVSpeechSynthesizer()
	
	var lastScanIndex: Int {
		
		let request = Scan.fetchRequest()
		do {
			let scans = try PersistenceController.shared.container.viewContext.fetch(request)
			return scans.count - 1
		} catch {
			print("Fetch failed")
		}
		
		return 0
	}
	
	func speak(text: String?) {
		guard let text = text else { return }
		
		if speechSynthesizer.isSpeaking {
			speechSynthesizer.stopSpeaking(at: .immediate)
		}
		let utterance = AVSpeechUtterance(string: text)
		utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

		speechSynthesizer.speak(utterance)
	}
	
	var isSpeaking: Bool {
		return speechSynthesizer.isSpeaking
	}
	
	func stopSpeaking() {
		if speechSynthesizer.isSpeaking {
			speechSynthesizer.stopSpeaking(at: .word)
		}
	}
	
	func requestReviewIfNecessary() {
		let minutesBetweenReviews = 10.0
		if lastReviewPrompt.addingTimeInterval(TimeInterval(minutesBetweenReviews*60)) < Date() {
			DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
				self.lastReviewPrompt = Date()
				self.requestReview()
			}
		}

	}
	
	func requestReview() {
		#if !os(xrOS)
		SKStoreReviewController.requestReview()
		#endif
	}
}


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
	let manager = CLLocationManager()

	@Published var location: CLLocationCoordinate2D?
	private var locations: [CLLocation] = [CLLocation]()

	override init() {
		super.init()
		manager.delegate = self
	}

	func requestLocation() {
		manager.requestWhenInUseAuthorization()
		locationManager(manager, didUpdateLocations: locations)
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		location = locations.first?.coordinate
	}
	
	var myLocation: CLLocation? {
		return manager.location
	}
}

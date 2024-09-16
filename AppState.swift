//
//  AppState.swift
//  scanner
//
//  Created by Slaven Radic on 2022-07-24.
//

import Foundation

class AppState: ObservableObject {
	
	public static let shared = AppState()
	
	@Published var viewState = ViewState.Home
	@Published var totalScans = 0
	
	@Published var iOS16Version = false
}


enum ViewState {
	case Home, Page, Live, About
}

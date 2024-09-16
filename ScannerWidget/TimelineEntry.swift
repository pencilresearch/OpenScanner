//
//  TimelineEntry.swift
//  ScannerWidgetExtension
//
//  Created by Slaven Radic on 2024-09-01.
//

import Foundation
import WidgetKit

struct ScanArrayEntry: TimelineEntry {
	let date: Date
	let configuration: ConfigurationIntent
	let entries: [ScanEntry]
}

struct ScanEntry {
	let title: String?
}

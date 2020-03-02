//
//  File.swift
//  
//
//  Created by Michael Redig on 3/2/20.
//

import Foundation

protocol ServerResponse: Codable, BetterDebugOutput {
	var cooldown: Double { get }
	var errors: [String] { get }
}

struct BasicResponse: ServerResponse {
	let cooldown: Double
	let errors: [String]
	let messages: [String]?
}

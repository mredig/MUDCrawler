//
//  File.swift
//  
//
//  Created by Michael Redig on 3/2/20.
//

import Foundation

struct ExamineResponse: ServerResponse {
	let name: String?
	let description: String
	let weight: Int?
	let itemtype: String?
	let level: Int?
	let exp: Int?
	let attributes: String?
	let cooldown: Double
	let errors: [String]
	let messages: [String]
}

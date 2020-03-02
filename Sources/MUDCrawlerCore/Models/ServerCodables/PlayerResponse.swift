//
//  File.swift
//  
//
//  Created by Michael Redig on 3/2/20.
//

import Foundation

struct PlayerResponse: ServerResponse {
	let name: String
	let cooldown: Double
	let encumbrance: Int
	let strength: Int
	let speed: Int
	let gold: Int
	let bodywear: String?
	let footwear: String?
	let inventory: [String]?
	let abilities: [String]
	let status: [String]
	let hasMined: Bool
	let errors: [String]
	let messages: [String]
}

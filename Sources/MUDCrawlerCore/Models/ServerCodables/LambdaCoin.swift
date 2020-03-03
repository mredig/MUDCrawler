//
//  File.swift
//  
//
//  Created by Michael Redig on 3/2/20.
//

import Foundation

struct ProofSubmission: Codable {
	let proof: Int
}

struct LastProof: ServerResponse {
	let proof: Int
	let difficulty: Int
	let cooldown: Double
	let messages: [String]
	let errors: [String]
}

struct ProofResponse: ServerResponse {
	let index: Int
	let transactions: String
	let proof: Int
	let previousHash: String
	let cooldown: Double
	let messages: [String]
	let errors: [String]
}

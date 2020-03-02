//
//  File.swift
//  
//
//  Created by Michael Redig on 3/2/20.
//

import Foundation

struct NamedItem: Codable {
	let name: String
}

struct ConfirmingItem: Codable {
	let name: String
	let confirm: String?
}

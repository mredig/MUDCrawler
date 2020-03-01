//
//  File.swift
//  
//
//  Created by Michael Redig on 3/1/20.
//

import Foundation

enum Direction: String, Codable {
	case north = "n"
	case south = "s"
	case east = "e"
	case west = "w"
}

struct DirectionWrapper: Codable {
	let direction: Direction
}

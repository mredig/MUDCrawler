//
//  File.swift
//  
//
//  Created by Michael Redig on 3/1/20.
//

import Foundation

enum Direction: String, Codable, Hashable {
	case north = "n"
	case south = "s"
	case east = "e"
	case west = "w"

	var opposite: Direction {
		switch self {
		case .north:
			return .south
		case .south:
			return .north
		case .west:
			return .east
		case .east:
			return .west
		}
	}
}

struct DirectionWrapper: Codable {
	let direction: Direction
	let nextRoomID: String?
}

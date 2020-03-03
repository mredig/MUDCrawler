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
	case warp
	case recall

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
		case .warp:
			return .warp
		case .recall:
			return .recall
		}
	}
}

struct DirectionWrapper: Codable {
	let direction: Direction
	let nextRoomID: String?
}

struct DashWrapper: Codable {
	let direction: Direction
	let numRooms: String
	let nextRoomIds: String
}

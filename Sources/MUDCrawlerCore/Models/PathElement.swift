//
//  File.swift
//  
//
//  Created by Michael Redig on 3/2/20.
//

import Foundation

struct PathElement<T> {
	let direction: T
	let roomID: Int
}

enum MovementType: CustomDebugStringConvertible {
	case move(direction: Direction, roomID: Int)
	case fly(direction: Direction, roomID: Int)
	case dash(direction: Direction, roomIDs: [Int])

	var debugDescription: String {
		switch self {
		case .move(direction: let dir, roomID: let id):
			return "move: \(dir) - \(id)"
		case .dash(direction: let dir, roomIDs: let ids):
			return "dash: \(dir) - \(ids)"
		case .fly(direction: let dir, roomID: let id):
			return "fly: \(dir) - \(id)"
		}
	}
}

extension Array where Element == PathElement<Direction> {
	func poweredUp(rooms: [Int: RoomLog]) -> [MovementType] {

		// first check for consecutive directions for dash

		// then check to see if any no dash room is elevated (MOUNTAIN) and set to fly

		// otherwise move
		var movements = [MovementType]()
		var iterator = 0
		while iterator < self.count {
			let previousElement: PathElement<Direction>?
			if iterator > 0 {
				previousElement = self[iterator - 1]
			} else {
				previousElement = nil
			}
			let basePathElement = self[iterator]
			var offset = 1
			let baseDirection = basePathElement.direction
			var dashRooms = [basePathElement.roomID]

			while (iterator + offset) < self.count {
				let offsetPathElement = self[iterator + offset]
				guard offsetPathElement.direction == baseDirection else { break }
				dashRooms.append(offsetPathElement.roomID)
				offset += 1
			}
			if dashRooms.count > 2 {
				movements.append(.dash(direction: baseDirection, roomIDs: dashRooms))
				iterator += dashRooms.count
			} else if let previousElement = previousElement, rooms[previousElement.roomID]?.terrain == "CAVE" {
				movements.append(.move(direction: baseDirection, roomID: basePathElement.roomID))
				iterator += 1
			} else {
				movements.append(.fly(direction: baseDirection, roomID: basePathElement.roomID))
				iterator += 1
			}
		}
		return movements
	}
}

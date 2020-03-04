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
	case warp(direction: Direction, roomID: Int)
	case recall

	var debugDescription: String {
		switch self {
		case .move(direction: let dir, roomID: let id):
			return "move: \(dir) - \(id)"
		case .dash(direction: let dir, roomIDs: let ids):
			return "dash: \(dir) - \(ids)"
		case .fly(direction: let dir, roomID: let id):
			return "fly: \(dir) - \(id)"
		case .warp(direction: _, roomID: let id):
			return "warp: \(id)"
		case .recall:
			return "recall"
		}
	}

	var resultingRoomID: Int? {
		switch self {
		case .dash(direction: _, roomIDs: let ids):
			return ids.last
		case .fly(direction: _, roomID: let id):
			return id
		case .move(direction: _, roomID: let id):
			return id
		case .recall:
			return 0
		case .warp(direction: _, roomID: let id):
			return id
		}
	}

	func approxCost(from previousMovement: MovementType?, rooms: [Int: RoomLog]) -> Double {
		let previousRoomID = previousMovement?.resultingRoomID

		var baseCost: Double = 7.5
		switch self {
		case .move(direction: _, roomID: let roomID):
			guard let room = rooms[roomID] else { return 100 }
			if room.isTrap {
				baseCost += 30
			}
			if let previousRoomID = previousRoomID, let previousRoom = rooms[previousRoomID] {
				if room.elevation > previousRoom.elevation {
					baseCost += 5
				}
			}
		case .fly(direction: _, roomID: let roomID):
			guard let room = rooms[roomID] else { return 100 }
			if room.isCave {
				baseCost += 10
			}
			if room.isTrap {
				baseCost += 30
			}
			baseCost *= 0.9
		case .dash(direction: _, roomIDs: let roomIDs):
			guard let lastID = roomIDs.last, let lastRoom = rooms[lastID] else { return 100 }
			baseCost *= 2
			baseCost += Double(roomIDs.count) * 0.5
			for i in (1..<roomIDs.count) {
				guard let previousRoom = rooms[roomIDs[i - 1]], let thisRoom = rooms[roomIDs[i]] else { continue }
				if previousRoom.elevation > thisRoom.elevation {
					baseCost -= 0.5
				} else if previousRoom.elevation < thisRoom.elevation {
					baseCost += 0.5
				}
			}
			if lastRoom.isTrap {
				baseCost += 30
			}
		case .recall:
			baseCost *= 2
		case .warp(direction: _, roomID: let roomID):
			guard let room = rooms[roomID] else { return 100 }
			baseCost *= 2
			if room.isTrap {
				baseCost += 30
			}
		}
		return baseCost
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
			guard basePathElement.direction != .warp else {
				movements.append(.warp(direction: .warp, roomID: basePathElement.roomID))
				iterator += 1
				continue
			}
			guard basePathElement.direction != .recall else {
				movements.append(.recall)
				iterator += 1
				continue
			}
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

extension Array where Element == MovementType {
	func totalApproxCost(rooms: [Int: RoomLog]) -> Double {
		var accumulator: Double = 0
		var previousElement: MovementType?
		for movement in self {
			accumulator += movement.approxCost(from: previousElement, rooms: rooms)
			previousElement = movement
		}
		return accumulator
	}
}

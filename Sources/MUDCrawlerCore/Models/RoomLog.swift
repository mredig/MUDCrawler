//
//  File.swift
//  
//
//  Created by Michael Redig on 3/1/20.
//

import Foundation

class RoomLog: Codable, Equatable {
	static func == (lhs: RoomLog, rhs: RoomLog) -> Bool {
		lhs.id == rhs.id &&
		lhs.location == rhs.location &&
		lhs.connections == rhs.connections
	}

	let id: Int
	let location: RoomLocation
	var connections: [Direction: Int]

	init(id: Int, location: RoomLocation) {
		self.id = id
		self.location = location
		connections = [Direction: Int]()
	}

	func connect(room: RoomLog, in direction: Direction) {
		guard connections[direction] != room.id else { return }
		guard connections[direction] == nil else { fatalError("Room \(self.id) already connected to another room! \(connections[direction] as Any)") }

		connections[direction] = room.id
		room.connect(room: self, in: direction.opposite)
	}
}

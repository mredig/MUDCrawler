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
}

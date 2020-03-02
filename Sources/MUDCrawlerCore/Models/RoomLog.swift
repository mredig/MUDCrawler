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
	var title: String
	var description: String
	let location: RoomLocation
	var connections: [Direction: Int]
	var unknownConnections = Set<Direction>()
	let elevation: Double?
	let terrain: String?
	var items: [String]?
	var messages: Set<String>

	init(id: Int, title: String, description: String, location: RoomLocation, elevation: Double?, terrain: String?, items: [String]?, messages: Set<String>) {
		self.id = id
		self.location = location
		connections = [Direction: Int]()
		self.elevation = elevation
		self.terrain = terrain
		self.items = items
		self.title = title
		self.description = description
		self.messages = messages
	}
}

//
//  File.swift
//  
//
//  Created by Michael Redig on 3/1/20.
//

import Foundation

struct RoomResponse: ServerResponse {
	let roomId: Int
	var roomID: Int {
		roomId
	}
	let title: String
	let description: String
	let coordinates: RoomLocation
	let elevation: Double?
	let terrain: String?
	let players: [String]?
	let items: [String]?
	let exits: [String]
	let cooldown: Double
	let errors: [String]
	let messages: [String]

	enum CodingKeys: String, CodingKey {
		case roomId
		case title
		case description
		case coordinates
		case elevation
		case terrain
		case players
		case items
		case exits
		case cooldown
		case errors
		case messages
	}
}

extension RoomResponse: CustomDebugStringConvertible {
	var debugDescription: String {
		"""
		id: \(roomID)
		title: \(title)
		description: \(description)
		coordinates: \(coordinates)
		elevation: \(elevation ?? 0)
		terrain: \(terrain ?? "")
		players: \(players ?? [])
		items: \(items ?? [])
		exits: \(exits)
		cooldown: \(cooldown)
		errors: \(errors)
		messages: \(messages)
		"""
	}
}

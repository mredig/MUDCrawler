//
//  File.swift
//  
//
//  Created by Michael Redig on 3/1/20.
//

import Foundation
import Files
import NetworkHandler

class RoomController {

	private(set) var rooms = [Int: RoomLog]()
	private(set) var currentRoom: Int?
	private let apiConnection = ApiConnection(token: "a010c017b8562e13b8f933b546a71caccca1c990")
	private(set) var waitingForResponse = false
	private(set) var cooldownExpiration = Date()

	init() {
		simpleLoadFromPersistentStore()
	}

	func initPlayer(completion: ((Result<RoomResponse, NetworkError>) -> Void)? = nil) {
		prepareToSendCommand()
		apiConnection.initPlayer { result in
			switch result {
			case .success(let roomInfo):
				self.updateCooldown(roomInfo.cooldown)
				self.logRoomInfo(roomInfo, movedInDirection: nil)
				print(roomInfo)
			case .failure(let error):
				print("there was an error: \(error)")
			}
			self.commandCompleted()
			completion?(result)
		}
	}

	func move(in direction: Direction, completion: ((Result<RoomResponse, NetworkError>) -> Void)? = nil) {
		guard let currentRoom = currentRoom else { return }
		prepareToSendCommand()

		let nextRoomID: String?
		if let nextID = rooms[currentRoom]?.connections[direction] {
			nextRoomID = "\(nextID)"
		} else {
			nextRoomID = nil
		}

		apiConnection.movePlayer(direction: direction, predictedRoom: nextRoomID) { result in
			switch result {
			case .success(let roomInfo):
				print(roomInfo)
				self.updateCooldown(roomInfo.cooldown)
				self.logRoomInfo(roomInfo, movedInDirection: direction)
			case .failure(let error):
				print("Error moving rooms: \(error)")
			}
			self.commandCompleted()
			completion?(result)
		}

	}

	private func logRoomInfo(_ roomInfo: RoomResponse, movedInDirection direction: Direction?) {
		let previousRoomID = currentRoom
		currentRoom = roomInfo.roomID

		updateMessages(roomInfo.messages, forRoom: roomInfo.roomID)
		guard rooms[roomInfo.roomID] == nil else { return }
		let room = RoomLog(id: roomInfo.roomID,
						   location: roomInfo.coordinates,
						   elevation: roomInfo.elevation,
						   terrain: roomInfo.terrain,
						   items: roomInfo.items,
						   messages: Set(roomInfo.messages))
		rooms[roomInfo.roomID] = room
		roomInfo.exits.forEach {
			guard let unknownDirection = Direction(rawValue: $0) else { return }
			room.unknownConnections.insert(unknownDirection)
		}

		if let previousRoomID = previousRoomID, let direction = direction {
			guard let previousRoom = rooms[previousRoomID] else { fatalError("Previous room: \(previousRoomID) not logged!") }
			connect(previousRoom: previousRoom, newRoom: room, direction: direction)
		}
		simpleSaveToPersistentStore()
	}

	private func updateMessages(_ messages: [String], forRoom roomID: Int) {
		let newMessages = Set(messages)
		rooms[roomID]?.messages.formUnion(newMessages)
	}

	private func connect(previousRoom: RoomLog, newRoom: RoomLog, direction: Direction) {
		// double check direction and positions match (this might not be necessary, but just verifying)
		switch direction {
		case .north:
			precondition(previousRoom.location.x == newRoom.location.x)
			precondition(previousRoom.location.y + 1 == newRoom.location.y)
		case .south:
			precondition(previousRoom.location.x == newRoom.location.x)
			precondition(previousRoom.location.y == newRoom.location.y + 1)
		case .west:
			precondition(previousRoom.location.x == newRoom.location.x + 1)
			precondition(previousRoom.location.y == newRoom.location.y)
		case .east:
			precondition(previousRoom.location.x + 1 == newRoom.location.x)
			precondition(previousRoom.location.y == newRoom.location.y)
		}

		connectOneWay(startingIn: previousRoom, endingIn: newRoom, direction: direction)
		connectOneWay(startingIn: newRoom, endingIn: previousRoom, direction: direction.opposite)
	}

	private func connectOneWay(startingIn previousRoom: RoomLog, endingIn newRoom: RoomLog, direction: Direction) {
		if previousRoom.connections[direction] != nil && previousRoom.connections[direction] != newRoom.id {
			fatalError("Room \(previousRoom.id) is already connected to \(previousRoom.connections[direction] ?? -1) in that direction! \(direction). Attempted to connect to \(newRoom.id)")
		}
		previousRoom.connections[direction] = newRoom.id
		previousRoom.unknownConnections.remove(direction)
	}

	// MARK: - Wait functions
	private func prepareToSendCommand() {
		waitForCooldown()
		waitingForResponse = true
	}

	private func commandCompleted() {
		waitingForResponse = false
	}

	func waitForCooldown() {
		var printedNotice = false
		while Date().timeIntervalSince1970 < cooldownExpiration.timeIntervalSince1970 {
			if !printedNotice {
				print("waiting for cooldown...")
				printedNotice = true
			}
			usleep(10000)
		}
	}

	func waitForResponse() {
		var printedNotice = false
		while waitingForResponse {
			if !printedNotice {
				print("waiting for response...")
				printedNotice = true
			}
			usleep(10000)
		}
	}

	func updateCooldown(_ cooldown: TimeInterval) {
		cooldownExpiration = Date(timeIntervalSinceNow: cooldown)
	}

	// MARK: - Persistence
	private func getFilePaths() throws -> (plistFile: File, jsonFile: File) {
		let folder = try Folder
			.home
			.createSubfolderIfNeeded(withName: "Documents")
			.createSubfolderIfNeeded(withName: "MUDmap")

		let plistFile = try folder.createFileIfNeeded(withName: "map.plist")
		let jsonFile = try folder.createFileIfNeeded(withName: "map.json")
		return (plistFile, jsonFile)
	}

	private func simpleLoadFromPersistentStore() {
		do {
			try loadFromPersistentStore()
		} catch {
			print("Error loading data from plist: \(error)")
		}
	}

	private func loadFromPersistentStore() throws {
		let (plistPath, _) = try getFilePaths()
		let plistData = try plistPath.read()
		rooms = try PropertyListDecoder().decode([Int: RoomLog].self, from: plistData)
	}

	private func simpleSaveToPersistentStore() {
		do {
			try saveToPersistentStore()
		} catch {
			print("Error saving data: \(error)")
		}
	}

	private func saveToPersistentStore() throws {
		let (plistOut, jsonOut) = try getFilePaths()

		let plistData = try PropertyListEncoder().encode(rooms)
		let jsonData = try JSONEncoder().encode(rooms)

		try plistOut.write(plistData)
		try jsonOut.write(jsonData)
	}
}

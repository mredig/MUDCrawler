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
	enum RoomControllerError: Error {
		case roomDoesntExist(roomID: Int)
		case pathNotFound
	}

	private(set) var rooms = [Int: RoomLog]()
	private(set) var currentRoom: Int?
	private let apiConnection = ApiConnection(token: "a010c017b8562e13b8f933b546a71caccca1c990")

	let commandQueue = CommandQueue()

	var stopExploring = false

	init() {
		simpleLoadFromPersistentStore()
		commandQueue.start()
	}

	/// adds an init command to the queue and waits for the cooldown to finish
	func initPlayer(completion: ((Result<RoomResponse, NetworkError>) -> Void)? = nil) {
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.initPlayer { result in
				let cdTime: Date
				switch result {
				case .success(let roomInfo):
					cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
					self.logRoomInfo(roomInfo, movedInDirection: nil)
					print(roomInfo)
				case .failure(let error):
					print("Error initing player: \(error)")
					cdTime = Date()
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	/// adds a move command to the queue and waits for the cooldown to finish
	func move(in direction: Direction, completion: ((Result<RoomResponse, NetworkError>) -> Void)? = nil) {
		guard let currentRoom = currentRoom else { return }

		let nextRoomID: String?
		if let nextID = rooms[currentRoom]?.connections[direction] {
			nextRoomID = "\(nextID)"
		} else {
			nextRoomID = nil
		}

		commandQueue.addCommand { dateCompletion in
			self.apiConnection.movePlayer(direction: direction, predictedRoom: nextRoomID) { result in
				let cdTime: Date
				switch result {
				case .success(let roomInfo):
					cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
					self.logRoomInfo(roomInfo, movedInDirection: direction)
					print(roomInfo)
				case .failure(let error):
					print("Error moving rooms: \(error)")
					cdTime = Date()
				}
				dateCompletion(cdTime)
				completion?(result)
			}
		}

		waitForCommandQueue()
	}

	func go(to roomID: Int, quietly: Bool) throws {
		guard let currentRoom = currentRoom else { return }
		guard rooms[roomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: roomID) }

		let path = try shortestRoute(from: currentRoom, to: roomID)

		for step in path {
			let direction = step.direction
			let room = step.roomID
			commandQueue.addCommand { dateCompletion in
				self.apiConnection.movePlayer(direction: direction, predictedRoom: "\(room)") { result in
					let cdTime: Date
					switch result {
					case .success(let roomInfo):
						if quietly {
							print("Entered room \(roomInfo.roomID)")
						} else {
							print(roomInfo)
						}
						self.logRoomInfo(roomInfo, movedInDirection: direction)
						cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
					case .failure(let error):
						print("Error moving player: \(error)")
						cdTime = Date()
					}
					dateCompletion(cdTime)
				}
			}
			print("Added \(direction) to \(room) to queue.")
		}
		waitForCommandQueue()
	}

	/// Performs a breadth first search to get from start to destination
	func shortestRoute(from startRoomID: Int, to destinationRoomID: Int) throws -> [PathElement<Direction>] {
		guard rooms[startRoomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: startRoomID) }
		guard rooms[destinationRoomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: destinationRoomID) }

		let queue = Queue<[PathElement<Direction?>]>()
		queue.enqueue([PathElement(direction: nil, roomID: startRoomID)])
		var visited = Set<Int>()

		while queue.count > 0 {
			guard let path = queue.dequeue() else { continue }
			guard let lastPathElement = path.last else { continue }
			let endRoomID = lastPathElement.roomID
			if endRoomID == destinationRoomID {
				return path.compactMap {
					guard let direction = $0.direction else { return nil }
					return PathElement(direction: direction, roomID: $0.roomID)
				}
			}
			guard !visited.contains(endRoomID) else { continue }
			visited.insert(endRoomID)
			guard let endRoom = rooms[endRoomID] else { continue }
			for (direction, connectedRoomID) in endRoom.connections {
				var newPath = path
				newPath.append(PathElement(direction: direction, roomID: connectedRoomID))
				queue.enqueue(newPath)
			}
		}
		throw RoomControllerError.pathNotFound
	}

	func nearestUnexplored(from startRoomID: Int) throws -> [PathElement<Direction>] {
		guard rooms[startRoomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: startRoomID) }

		let queue = Queue<[PathElement<Direction?>]>()
		queue.enqueue([PathElement(direction: nil, roomID: startRoomID)])
		var visited = Set<Int>()

		while queue.count > 0 {
			guard let path = queue.dequeue() else { continue }
			guard let lastPathElement = path.last else { continue }
			let endRoomID = lastPathElement.roomID
			guard !visited.contains(endRoomID) else { continue }
			visited.insert(endRoomID)

			guard let endRoom = rooms[endRoomID] else { continue }
			if endRoom.unknownConnections.count > 0 {
				return path.compactMap {
					guard let direction = $0.direction else { return nil }
					return PathElement(direction: direction, roomID: $0.roomID)
				}
			}
			for (direction, connectedRoomID) in endRoom.connections {
				var newPath = path
				newPath.append(PathElement(direction: direction, roomID: connectedRoomID))
				queue.enqueue(newPath)
			}
		}
		throw RoomControllerError.pathNotFound
	}

	// double while loop over the path, first iterating each element, then the next loop looking forward until there's a different direction. condense somehow
//	func compactForDash(path: []) -> [PathElement]

	func explore() throws {
		stopExploring = false
		while !stopExploring {
			guard var currentRoom = currentRoom else { return }
			let pathToNearestUnexplored = try nearestUnexplored(from: currentRoom)
			if let lastElement = pathToNearestUnexplored.last {
				print("Room \(lastElement.roomID) still has unexplored rooms. Headed there now!\n\n")
				try go(to: lastElement.roomID, quietly: true)
				currentRoom = lastElement.roomID
			}

			if rooms.count.isMultiple(of: 5) {
				drawMap()
			}

			guard let room = rooms[currentRoom] else { return }
			guard let direction = room.unknownConnections.first else { continue }
			move(in: direction) { _ in
				print("Checked out a new room...\n\n")
			}
		}
	}

	func testQueue() {
		let directions: [Direction] = [.north, .south, .north, .south]

		var previousRoom = currentRoom!
		for direction in directions {
			let nextRoomID: String?
			if let nextID = rooms[previousRoom]?.connections[direction] {
				nextRoomID = "\(nextID)"
				previousRoom = nextID
			} else {
				nextRoomID = nil
			}
			commandQueue.addCommand { dateCompletion in
				self.apiConnection.movePlayer(direction: direction, predictedRoom: nextRoomID) { result in
					let cdTime: Date
					switch result {
					case .success(let roomInfo):
						cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
						self.logRoomInfo(roomInfo, movedInDirection: direction)
						print(roomInfo)
					case .failure(let error):
						print("Error moving player: \(error)")
						cdTime = Date()
					}
					dateCompletion(cdTime)
				}
			}
			print("added move to \(nextRoomID)")
		}
		waitForCommandQueue()
	}

	private func logRoomInfo(_ roomInfo: RoomResponse, movedInDirection direction: Direction?) {
		let previousRoomID = currentRoom
		currentRoom = roomInfo.roomID

		updateMessages(roomInfo.messages, forRoom: roomInfo.roomID)
		if rooms[roomInfo.roomID] == nil {
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
		}
		guard let room = rooms[roomInfo.roomID] else { return }

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

	// MARK: - Visual
	func drawMap() {
		let size = rooms.reduce(RoomLocation(x: 0, y: 0)) {
			RoomLocation(x: max($0.x, $1.value.location.x), y: max($0.y, $1.value.location.y))
		}

		let row = (0...size.x).map { _ in "     " }
		var matrix = (0...size.y).map { _ in row }

		for (id, room) in rooms {
			let location = room.location
			var char = room.unknownConnections.isEmpty ? "\(id)" : "\(id)?"
			char = room.id == 0 ? "O" : char
			char = room.id == 1 ? "S" : char

			while char.count < 5 {
				char = " \(char) "
			}
			while char.count > 5 {
				char.removeLast()
			}

			matrix[location.y][location.x] = char
		}

		let flipped = matrix.reversed()

		let strings = flipped.map { $0.joined(separator: "") }

		for row in strings {
			print(row)
		}
	}

	// MARK: - Wait functions
	private func waitForCommandQueue() {
		var printedNotice = false
		var lastTimeNotice = Date(timeIntervalSinceNow: -1)
		while commandQueue.commandCount > 0 || commandQueue.currentlyExecuting {
			if !printedNotice {
				print("waiting for command queue to finish...", terminator: "")
				printedNotice = true
			}
			if lastTimeNotice.addingTimeInterval(1) < Date() {
				lastTimeNotice = Date()
				let difference = Int(commandQueue.earliestNextCommand.timeIntervalSince1970 - lastTimeNotice.timeIntervalSince1970)
				print(difference, terminator: difference > 0 ? " " : "\n")
			}
			usleep(10000)
		}
	}

	private func dateFromCooldownValue(_ cooldown: TimeInterval) -> Date {
		Date(timeIntervalSinceNow: cooldown)
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
		let jsonEnc = JSONEncoder()
		jsonEnc.keyEncodingStrategy = .convertToSnakeCase
		let jsonData = try jsonEnc.encode(rooms)

		try plistOut.write(plistData)
		try jsonOut.write(jsonData)
	}
}

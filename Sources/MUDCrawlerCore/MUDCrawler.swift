import Foundation
import NetworkHandler

public class MUDCrawler {

	let roomController = RoomController()

	var waitingForResponse = false

	var cooldownExpiration = Date()

	public init() {}

	public func start() {
		while true {
			gameLoop()
		}
	}

	public func startSnitchMine() {
		while true {
			roomController.initPlayer()
			roomController.snitchMining()
		}
	}

	// MARK: - Game Loop
	public func gameLoop() {
		let command = promptPlayerInput()
		performCommand(command)
	}

	func promptPlayerInput() -> String {
		print("\nWhat would you like to do?: ", terminator: "")
		guard let userInput = readLine(strippingNewline: true) else { return "" }
		return userInput.lowercased()
	}

	// MARK: - Command handling
	let directions = Set("nswe".map { String($0) })
	func performCommand(_ command: String) {
		if command == "init" {
			roomController.initPlayer()
		}
		else if directions.contains(command) {
			guard let direction = Direction(rawValue: command) else { return }
			roomController.fly(in: direction)
		}
		else if command.hasPrefix("go ") {
			gotoRoom(command: command)
		}
		else if command == "draw" {
			roomController.drawMap()
		}
		else if command == "treasurehunt" {
			roomController.treasureHunt()
		}
		else if command == "automine" {
			roomController.autoMine()
		}
		else if command == "snitchmine" {
			roomController.snitchMining()
		}
		else if command == "wander" {
			roomController.wanderInDarkWorld()
		}
		else if command.hasPrefix("take") {
			takeItem(command: command)
		}
		else if command.hasPrefix("drop") {
			dropItem(command: command)
		}
		else if command.hasPrefix("examine") {
			examine(command: command)
		}
		else if command == "gather" {
			roomController.gatherTreasure()
		}
		else if command.hasPrefix("buydonut") {
			roomController.buyDonut()
		}
		else if command.hasPrefix("sellall") {
			roomController.sellAllItems()
		}
		else if command.hasPrefix("sell") {
			sellItem(command: command)
		}
		else if command == "status" {
			roomController.getPlayerStatus()
		}
		else if command.hasPrefix("move") {
			move(command: command)
		}
		else if command.hasPrefix("equip") {
			equip(command: command)
		}
		else if command.hasPrefix("unequip") {
			unequip(command: command)
		}
		else if command.hasPrefix("give") {
			ghostGive(command: command)
		}
		else if command.hasPrefix("receive") {
			ghostTake(command: command)
		}
		else if command.hasPrefix("newname") {
			changeName(command: command)
		}
		else if command.hasPrefix("transmog") {
			transmog(command: command)
		}
		else if command.hasPrefix("dist") {
			distance(command: command)
		}
		else if command == "pray" {
			roomController.pray()
		}
		else if command == "warp" {
			roomController.warp()
		}
		else if command == "recall" {
			roomController.recall()
		}
		else if command == "getproof" {
			roomController.getLastProof()
		}
		else if command == "mine" {
			roomController.mine()
		}
		else if command == "balance" {
			roomController.getBalance()
		}
		else if command == "founditems" {
			roomController.foundItems()
		}
		else if command == "explore" {
			do {
				try roomController.explore()
			} catch {
				print("Error exploring: \(error)")
			}
		}
		else {
			print("\(command) is an invalid command. Try again.")
		}
	}

	// MARK: - Command filters
	func gotoRoom(command: String) {
		guard let destination = command.split(separator: " ").last, let destID = Int(destination) else {
			print("\(command) is invalid. Try again")
			return
		}
		do {
			try roomController.go(to: destID, quietly: true)
		} catch {
			print("Error going to room: \(error)")
		}
	}

	func takeItem(command: String) {
		let item = command.replacingOccurrences(of: "^take ", with: "", options: .regularExpression, range: nil)
		roomController.take(item: item)
	}

	func dropItem(command: String) {
		let item = command.replacingOccurrences(of: "^drop ", with: "", options: .regularExpression, range: nil)
		roomController.drop(item: item)
	}

	func sellItem(command: String) {
		let item = command.replacingOccurrences(of: "^sell ", with: "", options: .regularExpression, range: nil)
		roomController.sell(item: item, confirm: true)
	}

	func examine(command: String) {
		let entity = command.replacingOccurrences(of: "^examine ", with: "", options: .regularExpression, range: nil)
		roomController.examine(entity: entity)
	}

	func changeName(command: String) {
		var newName = command.replacingOccurrences(of: "^newname ", with: "", options: .regularExpression, range: nil)
		let confirm: Bool
		if command.hasSuffix(" y") {
			confirm = true
			newName = newName.replacingOccurrences(of: " y$", with: "", options: .regularExpression, range: nil)
		} else {
			confirm = false
		}
		roomController.changeName(to: newName, confirm: confirm)
	}

	func equip(command: String) {
		let gear = command.replacingOccurrences(of: "^equip ", with: "", options: .regularExpression, range: nil)
		roomController.equip(item: gear)
	}

	func unequip(command: String) {
		let gear = command.replacingOccurrences(of: "^unequip ", with: "", options: .regularExpression, range: nil)
		roomController.unequip(item: gear)
	}

	func move(command: String) {
		let directionRaw = command.replacingOccurrences(of: "^move ", with: "", options: .regularExpression, range: nil)
		guard let direction = Direction(rawValue: directionRaw) else { return }

		roomController.move(in: direction)
	}

	func distance(command: String) {
		let roomIDStr = command.replacingOccurrences(of: "^dist ", with: "", options: .regularExpression, range: nil)
		let rooms = roomIDStr.split(separator: " ").compactMap { Int($0) }
		let startRoom: Int
		let endRoom: Int

		if rooms.count == 1 {
			guard let currentRoom = roomController.currentRoom else {
				print("No current room")
				return
			}
			startRoom = currentRoom
			endRoom = rooms[0]
		} else if rooms.count == 2 {
			startRoom = rooms[0]
			endRoom = rooms[1]
		} else {
			print("Path or room doesn't exist")
			return
		}
		let oldPath = try! roomController.shortestRoute(from: startRoom, to: endRoom)
		let oldRooms = oldPath.map { $0.roomID }.map { String($0) }.joined(separator: " -> ")
		print(oldRooms)
		let newPath = try! roomController.shortestRoutes(from: startRoom, to: endRoom)
		print(newPath)
	}

	func ghostGive(command: String) {
		let gear = command.replacingOccurrences(of: "^give ", with: "", options: .regularExpression, range: nil)
		roomController.ghostCarry(item: gear)
	}

	func ghostTake(command: String) {
		let gear = command.replacingOccurrences(of: "^take ", with: "", options: .regularExpression, range: nil)
		roomController.ghostReceive(item: gear)
	}

	func transmog(command: String) {
		let gear = command.replacingOccurrences(of: "^transmog ", with: "", options: .regularExpression, range: nil)
		roomController.transmog(item: gear)
	}
}

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
			roomController.move(in: direction)
		}
		else if command == "test" {
			roomController.testQueue()
		}
		else if command.hasPrefix("go ") {
			gotoRoom(command: command)
		}
		else if command == "draw" {
			roomController.drawMap()
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
		else if command.hasPrefix("sell") {
			sellItem(command: command)
		}
		else if command == "status" {
			roomController.playerStatus()
		}
		else if command.hasPrefix("fly") {
			fly(command: command)
		}
		else if command.hasPrefix("equip") {
			equip(command: command)
		}
		else if command.hasPrefix("unequip") {
			unequip(command: command)
		}
		else if command.hasPrefix("newname") {
			changeName(command: command)
		}
		else if command == "pray" {
			roomController.pray()
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
		var item = command.replacingOccurrences(of: "^sell ", with: "", options: .regularExpression, range: nil)
		let confirm: Bool
		if command.hasSuffix(" y") {
			confirm = true
			item = item.replacingOccurrences(of: " y$", with: "", options: .regularExpression, range: nil)
		} else {
			confirm = false
		}
		roomController.sell(item: item, confirm: confirm)
	}

	func examine(command: String) {
		let entity = command.replacingOccurrences(of: "^examine ", with: "", options: .regularExpression, range: nil)
		roomController.examine(entity: entity)
	}

	func changeName(command: String) {
		let newName = command.replacingOccurrences(of: "^newname ", with: "", options: .regularExpression, range: nil)
		roomController.changeName(to: newName)
	}

	func equip(command: String) {
		let gear = command.replacingOccurrences(of: "^equip ", with: "", options: .regularExpression, range: nil)
		roomController.equip(item: gear)
	}

	func unequip(command: String) {
		let gear = command.replacingOccurrences(of: "^unequip ", with: "", options: .regularExpression, range: nil)
		roomController.unequip(item: gear)
	}

	func fly(command: String) {
		let directionRaw = command.replacingOccurrences(of: "^fly ", with: "", options: .regularExpression, range: nil)
		guard let direction = Direction(rawValue: directionRaw) else { return }

		roomController.fly(in: direction)
	}
}

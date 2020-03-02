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

	public func gameLoop() {
		let command = promptPlayerInput()
		performCommand(command)
	}

	let directions = Set("nswe".map { String($0) })
	func performCommand(_ command: String) {
		if command == "init" {
			roomController.initPlayer()
		} else if directions.contains(command) {
			guard let direction = Direction(rawValue: command) else { return }
			roomController.move(in: direction)
		} else if command == "test" {
			roomController.testQueue()
		} else {
			print("\(command) is an invalid command. Try again.")
		}
	}

	func promptPlayerInput() -> String {
		print("\nWhat would you like to do?: ", terminator: "")
		guard let userInput = readLine(strippingNewline: true) else { return "" }
		return userInput.lowercased()
	}
}

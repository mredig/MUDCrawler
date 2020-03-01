import Foundation
import NetworkHandler

public class MUDCrawler {

//	let apiConnection = ApiConnection(token: "a010c017b8562e13b8f933b546a71caccca1c990")
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
		roomController.waitForResponse()

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
		} else {
			print("\(command) is an invalid command. Try again.")
		}
	}

	func promptPlayerInput() -> String {
		print("\nWhat would you like to do?: ", terminator: "")
		guard let userInput = readLine(strippingNewline: true) else { return "" }
		return userInput.lowercased()
	}

	// MARK: - API calls
//	func initializePlayer() {
//		waitingForResponse = true
//		apiConnection.initPlayer { result in
//			switch result {
//			case .success(let roomInfo):
//				print(roomInfo)
//				self.updateCooldown(roomInfo.cooldown)
//			case .failure(let error):
//				print("there was an error: \(error)")
//			}
//			self.waitingForResponse = false
//		}
//	}
//
//	func move(inDirection direction: String) {
//		guard let direction = Direction(rawValue: direction) else { return }
//		waitingForResponse = true
//
//		apiConnection.movePlayer(direction: direction) { (result: Result<RoomResponse, NetworkError>) in
//			switch result {
//			case .success(let roomInfo):
//				print(roomInfo)
//				self.updateCooldown(roomInfo.cooldown)
//			case .failure(let error):
//				print("Error moving rooms: \(error)")
//			}
//			self.waitingForResponse = false
//		}
//	}

}

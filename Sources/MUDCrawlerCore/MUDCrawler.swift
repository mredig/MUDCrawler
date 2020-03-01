import Foundation
import NetworkHandler

public class MUDCrawler {

	let apiConnection = ApiConnection(token: "a010c017b8562e13b8f933b546a71caccca1c990")

	public let value: Int
	var waitingForResponse = false

	var cooldownExpiration = Date()

	public init(value: Int) {
		self.value = value
	}

	public func start() {
		while true {
			gameLoop()
		}
	}

	public func gameLoop() {
		waitForResponse()

		let command = promptPlayerInput()
		performCommand(command)
	}

	let directions = Set("nswe".map { String($0) })
	func performCommand(_ command: String) {
		waitForCooldown()

		if command == "init" {
			initializePlayer()
		} else if directions.contains(command) {
			move(inDirection: command)
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
	func initializePlayer() {
		waitingForResponse = true
		apiConnection.initPlayer { result in
			switch result {
			case .success(let roomInfo):
				print(roomInfo)
				self.updateCooldown(roomInfo.cooldown)
			case .failure(let error):
				print("there was an error: \(error)")
			}
			self.waitingForResponse = false
		}
	}

	func move(inDirection direction: String) {
		guard let direction = Direction(rawValue: direction) else { return }
		waitingForResponse = true

		apiConnection.movePlayer(direction: direction) { (result: Result<RoomResponse, NetworkError>) in
			switch result {
			case .success(let roomInfo):
				print(roomInfo)
				self.updateCooldown(roomInfo.cooldown)
			case .failure(let error):
				print("Error moving rooms: \(error)")
			}
			self.waitingForResponse = false
		}
	}

	// MARK: - Wait functions
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
}

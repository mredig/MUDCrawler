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


	let directions = Set("nswe".map { String($0) })
	public func gameLoop() {
		waitForResponse()
		print("\nWhat would you like to do?: ", terminator: "")
		guard let userInput = readLine(strippingNewline: true) else { return }
		let userCmd = userInput.lowercased()

		waitForCooldown()

		print("doing \(userCmd)")
		thing()
		gameLoop()
	}

	public func thing() {
		waitingForResponse = true
		apiConnection.initPlayer { result in
			switch result {
			case .success(let roomInfo):
				print(roomInfo)
				self.cooldownExpiration = Date(timeIntervalSinceNow: roomInfo.cooldown)
			case .failure(let error):
				print("there was an error: \(error)")
			}
			self.waitingForResponse = false
		}
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
}

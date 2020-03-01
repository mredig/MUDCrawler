import Foundation
import NetworkHandler

public struct MUDCrawler {

	let apiConnection = ApiConnection(token: "a010c017b8562e13b8f933b546a71caccca1c990")

	public let value: Int

	public init(value: Int) {
		self.value = value
	}

	public func thing() {
		apiConnection.initPlayer { result in
			switch result {
			case .success(let roomInfo):
				print(roomInfo)
			case .failure(let error):
				print("there was an error: \(error)")
			}
		}

		let waitForUser = readLine(strippingNewline: true)
		print(waitForUser)
	}
}

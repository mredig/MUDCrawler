import Foundation
import NetworkHandler

public struct MUDCrawler {

	public let value: Int

	public init(value: Int) {
		self.value = value
	}

	public func thing() {
		print("Hello thing: \(value)")

		let apiconnection = ApiConnection(token: "a010c017b8562e13b8f933b546a71caccca1c990")

		apiconnection.initPlayer()

		let waitForUser = readLine(strippingNewline: true)
		print(waitForUser)
	}
}

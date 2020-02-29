import Foundation

public struct MUDCrawler {

	public let value: Int

	public init(value: Int) {
		self.value = value
	}

	public func thing() {
		print("Hello thing: \(value)")
	}
}

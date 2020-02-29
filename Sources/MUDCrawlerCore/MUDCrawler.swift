import Foundation
import NetworkHandlerSPM

public struct MUDCrawler {

	public let value: Int

	public init(value: Int) {
		self.value = value
	}

	public func thing() {
		print("Hello thing: \(value)")

		let handler = NetworkHandler.default

		let baseURL = URL(string: "http://imac.nl.redig.me:8080/overworld")!

		var request = baseURL.request
		request.addValue(.contentType(type: .json), forHTTPHeaderField: .commonKey(key: .contentType))


		handler.transferMahDatas(with: request) { result in
			switch result {
			case .success(let data):
				let str = String(data: data, encoding: .utf8)!
				print(str)
			case .failure(let error):
				print("Error: \(error)")
			}
		}
		let waitForUser = readLine(strippingNewline: true)
		print(waitForUser)
	}
}

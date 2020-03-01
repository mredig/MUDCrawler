//
//  File.swift
//  
//
//  Created by Michael Redig on 3/1/20.
//

import Foundation
import NetworkHandler

class ApiConnection {
	private let baseURL = URL(string: "http://localhost:8000")!

	var token: String

	init(token: String) {
		self.token = token
	}

	func getRequest(from url: URL) -> NetworkRequest {
		var request = url.request
		request.addValue(.contentType(type: .json), forHTTPHeaderField: .commonKey(key: .contentType))
		request.addValue(.other(value: "Token \(token)"), forHTTPHeaderField: .commonKey(key: .authorization))
		return request
	}

	func initPlayer(completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("init", isDirectory: true)

		let request = getRequest(from: url)

		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func movePlayer(direction: Direction, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("move", isDirectory: true)

		var request = getRequest(from: url)
		request.encodeData(DirectionWrapper(direction: direction))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}
}

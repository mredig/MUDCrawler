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

	var requestHeaders: [String: String]? {
		var request = baseURL.request
		request.addValue(.contentType(type: .json), forHTTPHeaderField: .commonKey(key: .contentType))
		request.addValue(.other(value: "Token \(token)"), forHTTPHeaderField: .commonKey(key: .authorization))
		return request.allHeaderFields
	}

	func initPlayer() {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("init", isDirectory: true)

		var request = url.request
		request.allHeaderFields = requestHeaders

		NetworkHandler.default.transferMahDatas(with: request) { result in
			switch result {
			case .success(let data):
				let str = String(data: data, encoding: .utf8)!
				print(str)
			case .failure(let error):
				print("there was an error: \(error)")
			}
		}
	}
}

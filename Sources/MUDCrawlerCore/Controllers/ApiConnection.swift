//
//  File.swift
//  
//
//  Created by Michael Redig on 3/1/20.
//

import Foundation
import NetworkHandler

class ApiConnection {
	private let baseURL = URL(string: "https://lambda-treasure-hunt.herokuapp.com")!

	var token: String

	init(token: String) {
		self.token = token
	}

	func getRequest(from url: URL, method: HTTPMethod) -> NetworkRequest {
		var request = url.request
		request.httpMethod = method
		request.addValue(.contentType(type: .json), forHTTPHeaderField: .commonKey(key: .contentType))
		request.addValue(.other(value: "Token \(token)"), forHTTPHeaderField: .commonKey(key: .authorization))

		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		request.encoder = encoder
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		request.decoder = decoder
		return request
	}

	func initPlayer(completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("init", isDirectory: true)

		let request = getRequest(from: url, method: .get)

		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func movePlayer(direction: Direction, predictedRoom: String?, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("move", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(DirectionWrapper(direction: direction, nextRoomID: predictedRoom))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func dashPlayer(direction: Direction, predictedRooms: [Int], completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("dash", isDirectory: true)

		let predictedRoomsStr = predictedRooms.map { String($0) }

		var request = getRequest(from: url, method: .post)
		request.encodeData(DashWrapper(direction: direction,
									   numRooms: String(predictedRooms.count),
									   nextRoomIds: predictedRoomsStr.joined(separator: ",")))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func fly(direction: Direction, predictedRoom: String?, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("fly", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(DirectionWrapper(direction: direction, nextRoomID: predictedRoom))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func warp(completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("warp", isDirectory: true)

		let request = getRequest(from: url, method: .post)
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func recall(completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("recall", isDirectory: true)

		let request = getRequest(from: url, method: .post)
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func takeItem(_ item: String, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("take", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(NamedItem(name: item))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func dropItem(_ item: String, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("drop", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(NamedItem(name: item))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func sellItem(_ item: String, confirm: Bool, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("sell", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(ConfirmingItem(name: item, confirm: confirm ? "yes" : nil))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func playerStatus(completion: @escaping (Result<PlayerResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("status", isDirectory: true)

		let request = getRequest(from: url, method: .post)
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func examine(entity: String, completion: @escaping (Result<ExamineResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("examine", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(NamedItem(name: entity))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	// FIXME: UNKNOWN RESULT TYPE
	func equip(item: String, completion: @escaping (Result<PlayerResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("wear", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(NamedItem(name: item))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	// FIXME: UNKNOWN RESULT TYPE
	func unequip(item: String, completion: @escaping (Result<PlayerResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("undress", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(NamedItem(name: item))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func changeName(newName: String, confirm: Bool, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("change_name", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(ConfirmingItem(name: newName, confirm: confirm ? "aye" : nil))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func pray(completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("pray", isDirectory: true)

		let request = getRequest(from: url, method: .post)
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func ghostCarry(item: String, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("carry", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(NamedItem(name: item))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func ghostReceive(item: String, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("receive", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(NamedItem(name: item))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func transmog(item: String, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("adv", isDirectory: true)
			.appendingPathComponent("transmogrify", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(NamedItem(name: item))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	// MARK: - lambda coin stuff
	// FIXME: UNKNOWN RESULT TYPE
	func submitProof(proof: Int, completion: @escaping (Result<ProofResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("bc", isDirectory: true)
			.appendingPathComponent("mine", isDirectory: true)

		var request = getRequest(from: url, method: .post)
		request.encodeData(ProofSubmission(proof: proof))
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func getLastProof(completion: @escaping (Result<LastProof, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("bc", isDirectory: true)
			.appendingPathComponent("last_proof", isDirectory: true)

		let request = getRequest(from: url, method: .get)
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}

	func getBalance(completion: @escaping (Result<BasicResponse, NetworkError>) -> Void) {
		let url = baseURL.appendingPathComponent("api", isDirectory: true)
			.appendingPathComponent("bc", isDirectory: true)
			.appendingPathComponent("get_balance", isDirectory: true)

		let request = getRequest(from: url, method: .get)
		NetworkHandler.default.transferMahCodableDatas(with: request, completion: completion)
	}
}

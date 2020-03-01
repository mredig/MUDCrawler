//
//  Vector.swift
//  App
//
//  Created by Michael Redig on 2/29/20.
//

import Foundation

struct RoomLocation: Hashable {
	let x: Int
	let y: Int

	init(x: Int, y: Int) {
		self.x = x
		self.y = y
	}

	init(point: CGPoint) {
		self.x = Int(point.x)
		self.y = Int(point.y)
	}
}

extension RoomLocation: Codable {
	enum VectorError: Error {
		case invalidEncodedFormat(source: String)
		case valueNAN(source: String)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let strValue = try container.decode(String.self)

		let split = strValue
			.replacingOccurrences(of: ##"[\(|\)]"##, with: "", options: .regularExpression, range: nil)
			.split(separator: ",")
			.map { String($0) }
		guard split.count == 2 else { throw VectorError.invalidEncodedFormat(source: strValue) }
		guard let x = Int(split[0]), let y = Int(split[1]) else { throw VectorError.valueNAN(source: strValue) }

		self.x = x
		self.y = y
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		let strValue = "(\(x),\(y))"
		try container.encode(strValue)
	}
}

extension RoomLocation: CustomDebugStringConvertible {
	var debugDescription: String {
		"(\(x),\(y))"
	}
}

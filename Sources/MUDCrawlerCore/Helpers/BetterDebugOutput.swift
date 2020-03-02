//
//  File.swift
//  
//
//  Created by Michael Redig on 3/2/20.
//

import Foundation

protocol BetterDebugOutput: CustomDebugStringConvertible {}

extension BetterDebugOutput {
	var debugDescription: String {
		let mirror = Mirror(reflecting: self)

		var output = "\(type(of: self)):\n\n"
		for child in mirror.children {
			guard let key = child.label else { continue }
			switch child.value {
			case Optional<Any>.none:
				continue
			default:
				break
			}
			output += "\(key): \(child.value)\n"
		}
		return output
	}
}

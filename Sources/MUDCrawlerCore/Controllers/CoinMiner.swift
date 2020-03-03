//
//  File.swift
//  
//
//  Created by Michael Redig on 3/2/20.
//

import Foundation
import CryptoKit

@available(OSX 10.15, *)
class CoinMiner {

	var lastProof: LastProof {
		didSet {
			updateDifficulty()
		}
	}
	let iterations: Int

	var difficultyStr: String = "000000"

	init(lastProof: LastProof, iterations: Int) {
		self.lastProof = lastProof
		self.iterations = iterations
		updateDifficulty()
	}

	func updateDifficulty() {
		difficultyStr = (0..<lastProof.difficulty).map { _ in "0" }.joined()
	}

	func validateProof(value: Int) -> Bool {
		let combined = combineProofs(testProof: value)
		return validate(string: combined)
	}

	func validate(string: String) -> Bool {
		guard let data = string.data(using: .utf8) else { return false }
		let hashStr = SHA256.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
		print(hashStr)
		return hashStr.hasPrefix(difficultyStr)
	}

	func mine() -> Int? {
		for _ in 0..<iterations {
			let testProof = Int.random(in: 0..<Int.max)
			let combined = combineProofs(testProof: testProof)
			if validate(string: combined) {
				return testProof
			}
		}
		return nil
	}

	func combineProofs(testProof: Int) -> String {
		"\(lastProof.proof)\(testProof)"
	}
}

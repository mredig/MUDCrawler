//
//  File.swift
//  
//
//  Created by Michael Redig on 3/2/20.
//

import Foundation
#if os(Linux)
import CryptoSwift
#else
import CryptoKit
#endif

public class CoinMiner {

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
		#if os(Linux)
		return string.sha256().hasPrefix(difficultyStr)
		#else
		guard let data = string.data(using: .utf8) else { return false }
		var hashStr = SHA256.hash(data: data).description
		hashStr.removeFirst(15)
		return hashStr.hasPrefix(difficultyStr)
		#endif
	}

	func mine() -> Int? {
		for _ in 0..<iterations {
			let testProof = Int(Int32.random(in: 0..<Int32.max))
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

//	public static func benchMark() {
//
//		let iterations = 9999
//		let startA = Date()
//		let example1 = (0...iterations).map {
//			String($0).sha256()
//		}.last
//		let endA = Date()
//
//		print("speed of a: \(endA.timeIntervalSince1970 - startA.timeIntervalSince1970): \(example1 ?? "")")
//
//		let startB = Date()
//		let example2: String? = (0...iterations).map {
//			guard let data = String($0).data(using: .utf8) else { return "  " }
//			var hashStr = SHA256.hash(data: data).description
//			hashStr.removeFirst(15)
//			return hashStr
//		}.last
//		let endB = Date()
//		print("speed of b: \(endB.timeIntervalSince1970 - startB.timeIntervalSince1970): \(example2 ?? "")")
//
//
//	}



}

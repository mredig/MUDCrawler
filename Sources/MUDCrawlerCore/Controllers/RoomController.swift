//
//  File.swift
//  
//
//  Created by Michael Redig on 3/1/20.
//

import Foundation
import Files
import NetworkHandler
import LS8Core
import CooldownCommandQueueCore

class RoomController {
	enum RoomControllerError: Error {
		case roomDoesntExist(roomID: Int)
		case pathNotFound
	}

	private(set) var playerStatus: PlayerResponse? {
		didSet {
			updateSugarRushExp()
		}
	}
	private(set) var sugarRushExpiration: Date?
	private(set) var rooms = [Int: RoomLog]()
	private(set) var currentRoom: Int?
	private let apiConnection = ApiConnection(token: apikey)
	private(set) var snitchCount: Int?
	private var missedLastSnitch = false
	private var goalSnitchRoom: Int?
	private var previousRoomID: Int? = 0

	let commandQueue = CommandQueue()
	let cdCommandQueue = CooldownCommandQueue {
		print("An error occurred. Try something else!")
	}

	var stopExploring = false

	init() {
		simpleLoadFromPersistentStore()
		commandQueue.start()
	}

	private func updateSugarRushExp() {
		guard let playerStatus = playerStatus else { return }
		guard let sugRush = playerStatus.sugarRush else { return }
		sugarRushExpiration = Date(timeIntervalSinceNow: sugRush - 20)
	}

	// MARK: - API Directives
	/// adds an init command to the queue and waits for the cooldown to finish
	func initPlayer(completion: ((Result<RoomResponse, NetworkError>) -> Void)? = nil) {
		let task = CooldownCommandOperation { cooldownCompletion in
			self.apiConnection.initPlayer { result in
				switch result {
				case .success(let roomResponse):
					self.logRoomInfo(roomResponse, movedInDirection: nil)
					print(roomResponse)
					cooldownCompletion(roomResponse.cooldown, true)
				case .failure(let error):
					print("Error initing player: \(error)")
					let cooldown = self.cooldownDurationFromError(error)
					cooldownCompletion(self.cooldownDurationFromError(error), cooldown > 0)
				}
			}
		}
		cdCommandQueue.addTask(task)
		waitForCooldownQueue()
	}

	func warp() {
		let warpTask = CooldownCommandOperation { cooldownCompletion in
			self.apiConnection.warp { result in
				switch result {
				case .success(let roomResponse):
					self.logRoomInfo(roomResponse, movedInDirection: nil)
					print(roomResponse)
					cooldownCompletion(roomResponse.cooldown, true)
				case .failure(let error):
					print("Error warping player: \(error)")
					let cooldown = self.cooldownDurationFromError(error)
					cooldownCompletion(self.cooldownDurationFromError(error), cooldown > 0)
				}
			}
		}
		cdCommandQueue.addTask(warpTask)
		waitForCooldownQueue()
	}

	func recall() {
		let recallTask = CooldownCommandOperation { cooldownCompletion in
			self.apiConnection.recall { result in
				switch result {
				case .success(let roomResponse):
					self.logRoomInfo(roomResponse, movedInDirection: nil)
					print(roomResponse)
					cooldownCompletion(roomResponse.cooldown, true)
				case .failure(let error):
					print("Error recalling player: \(error)")
					let cooldown = self.cooldownDurationFromError(error)
					cooldownCompletion(self.cooldownDurationFromError(error), cooldown > 0)
				}
			}
		}
		cdCommandQueue.addTask(recallTask)
		waitForCooldownQueue()
	}

	/// adds a move command to the queue and waits for the cooldown to finish
	func move(in direction: Direction, completion: ((Result<RoomResponse, NetworkError>) -> Void)? = nil) {
		guard let currentRoom = currentRoom else { return }

		let nextRoomID: String?
		if let nextID = rooms[currentRoom]?.connections[direction] {
			nextRoomID = "\(nextID)"
		} else {
			nextRoomID = nil
		}

		let moveTask = CooldownCommandOperation { cooldownCompletion in
			self.apiConnection.movePlayer(direction: direction, predictedRoom: nextRoomID) { result in
				switch result {
				case .success(let roomResponse):
					self.logRoomInfo(roomResponse, movedInDirection: direction)
					print(roomResponse)
					cooldownCompletion(roomResponse.cooldown, true)
				case .failure(let error):
					print("Error moving rooms: \(error)")
					let cooldown = self.cooldownDurationFromError(error)
					cooldownCompletion(self.cooldownDurationFromError(error), cooldown > 0)
				}
			}
		}
		cdCommandQueue.addTask(moveTask)
		waitForCooldownQueue()
	}

	func fly(in direction: Direction, completion: ((Result<RoomResponse, NetworkError>) -> Void)? = nil) {
		guard let currentRoom = currentRoom else { return }

		let nextRoomID: String?
		if let nextID = rooms[currentRoom]?.connections[direction] {
			nextRoomID = "\(nextID)"
		} else {
			nextRoomID = nil
		}

		let flyTask = CooldownCommandOperation { cooldownCompletion in
			self.apiConnection.fly(direction: direction, predictedRoom: nextRoomID) { result in
				switch result {
				case .success(let roomResponse):
					self.logRoomInfo(roomResponse, movedInDirection: direction)
					print(roomResponse)
					cooldownCompletion(roomResponse.cooldown, true)
				case .failure(let error):
					print("Error flying player: \(error)")
					let cooldown = self.cooldownDurationFromError(error)
					cooldownCompletion(self.cooldownDurationFromError(error), cooldown > 0)
				}
			}
		}
		cdCommandQueue.addTask(flyTask)
		waitForCooldownQueue()
	}

	func go(to roomID: Int, quietly: Bool) throws {
		guard let currentRoom = currentRoom else { return }
		guard rooms[roomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: roomID) }

		let movements = try shortestRoutes(from: currentRoom, to: roomID)

		let responseHandler = { [weak self] (result: Result<RoomResponse, NetworkError>, cooldownCompletion: CooldownCommandOperation.CooldownCompletion, direction: Direction?, dashed: Bool) -> Void in
			guard let self = self else { return }
			switch result {
			case .success(let roomResponse):
				self.logRoomInfo(roomResponse, movedInDirection: direction, dashed: dashed)
				if quietly {
					print("Entered room \(roomResponse.roomID)")
				} else {
					print(roomResponse)
				}
				cooldownCompletion(roomResponse.cooldown, true)
			case .failure(let error):
				print("Error during `go` function: \(error)")
				let cooldown = self.cooldownDurationFromError(error)
				cooldownCompletion(self.cooldownDurationFromError(error), cooldown > 0)
			}
		}

		for step in movements {
			switch step {
			case .dash(direction: let direction, roomIDs: let roomIDs):
				let dashTask = CooldownCommandOperation { cooldownCompletion in
					self.apiConnection.dashPlayer(direction: direction, predictedRooms: roomIDs) { result in
						responseHandler(result, cooldownCompletion, direction, true)
					}
				}
				cdCommandQueue.addTask(dashTask)
			case .fly(direction: let direction, roomID: let roomID):
				let flyTask = CooldownCommandOperation { cooldownCompletion in
					self.apiConnection.fly(direction: direction, predictedRoom: "\(roomID)") { result in
						responseHandler(result, cooldownCompletion, direction, false)
					}
				}
				cdCommandQueue.addTask(flyTask)
			case .move(direction: let direction, roomID: let roomID):
				let moveTask = CooldownCommandOperation { cooldownCompletion in
					self.apiConnection.movePlayer(direction: direction, predictedRoom: "\(roomID)") { result in
						responseHandler(result, cooldownCompletion, direction, false)
					}
				}
				cdCommandQueue.addTask(moveTask)

			case .warp(direction: _, roomID: _):
				let warpTask = CooldownCommandOperation { cooldownCompletion in
					self.apiConnection.warp { result in
						responseHandler(result, cooldownCompletion, nil, false)
					}
				}
				cdCommandQueue.addTask(warpTask)
			case .recall:
				let recallTask = CooldownCommandOperation { cooldownCompletion in
					self.apiConnection.recall { result in
						responseHandler(result, cooldownCompletion, nil, false)
					}
				}
				cdCommandQueue.addTask(recallTask)
			}
			print("Added \(step) to queue.")
		}
		waitForCooldownQueue()
	}

	private func createTakeTask(item: String) -> CooldownCommandOperation {
		let takeTask = CooldownCommandOperation { cooldownCompletion in
			self.apiConnection.takeItem(item) { result in
				switch result {
				case .success(let roomResponse):
					self.logRoomInfo(roomResponse, movedInDirection: nil)
					print(roomResponse)
					cooldownCompletion(roomResponse.cooldown, true)
				case .failure(let error):
					print("Error jump taking item: \(error)")
					let cooldown = self.cooldownDurationFromError(error)
					cooldownCompletion(self.cooldownDurationFromError(error), cooldown > 0)

				}
			}
		}
		return takeTask
	}

	func take(item: String) {
		guard currentRoom != nil else { return }
		let takeTask = createTakeTask(item: item)
		cdCommandQueue.jumpTask(takeTask)
		waitForCooldownQueue()
	}

	/// adds an item take to the front of the queue, but doesn't wait for it to complete
	func jumpTake(item: String) {
		guard currentRoom != nil else { return }
		let takeTask = createTakeTask(item: item)
		cdCommandQueue.jumpTask(takeTask)
	}

	func drop(item: String) {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.dropItem(item) { result in
				let cdTime: Date
				switch result {
				case .success(let roomInfo):
					cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
					self.logRoomInfo(roomInfo, movedInDirection: nil)
					print(roomInfo)
				case .failure(let error):
					print("Error dropping item: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func buyDonut() {
		guard currentRoom != nil else { return }
		try? go(to: 15, quietly: true)
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.buyDonut { result in
				let cdTime: Date
				switch result {
				case .success(let roomInfo):
					cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
					self.logRoomInfo(roomInfo, movedInDirection: nil)
					print(roomInfo)
				case .failure(let error):
					print("Error selling item: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func gatherTreasure() {
		getPlayerStatus()
		while (playerStatus?.capacity ?? 1) < 0.66 {
			var roomNum = Int.random(in: 200...499)
			roomNum = Int.random(in: 0..<10) == 0 ? 495 : roomNum
			print("Wandering to \(roomNum)\n")
			try? go(to: roomNum, quietly: true)
			getPlayerStatus()
		}
	}

	func sell(item: String, confirm: Bool) {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.sellItem(item, confirm: confirm) { result in
				let cdTime: Date
				switch result {
				case .success(let roomInfo):
					cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
					self.logRoomInfo(roomInfo, movedInDirection: nil)
					print(roomInfo)
				case .failure(let error):
					print("Error selling item: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func sellAllItems() {
		guard currentRoom != nil else { return }
		getPlayerStatus()
		guard let playerStatus = playerStatus, let items = playerStatus.inventory else { return }
		guard items.count > 0 else { return }
		try? go(to: 1, quietly: true)
		for item in items {
			commandQueue.addCommand { dateCompletion in
				self.apiConnection.sellItem(item, confirm: true) { result in
					let cdTime: Date
					switch result {
					case .success(let roomInfo):
						cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
						self.logRoomInfo(roomInfo, movedInDirection: nil)
						print(roomInfo)
					case .failure(let error):
						print("Error selling item: \(error)")
						cdTime = self.cooldownFromError(error)
					}
					dateCompletion(cdTime)
				}
			}
		}
		waitForCommandQueue()
		getPlayerStatus()
	}

	func examine(entity: String) {
		guard currentRoom != nil else { return }

		if entity == "well" {
			guard let newRoomID = examineWell() else { return }
			print("Mine in room \(newRoomID)")
		} else {
			commandQueue.addCommand { dateCompletion in
				self.apiConnection.examine(entity: entity) { result in
					let cdTime: Date
					switch result {
					case .success(let examineResponse):
						cdTime = self.dateFromCooldownValue(examineResponse.cooldown)
						print(examineResponse)
						if entity == "well", let id = self.getRoomID(from: examineResponse.description) {
							print("Mine in room \(id)")
						}
					case .failure(let error):
						print("Error examining item: \(error)")
						cdTime = self.cooldownFromError(error)
					}
					dateCompletion(cdTime)
				}
			}
			waitForCommandQueue()
		}
	}

	func examineWell() -> Int? {
		guard currentRoom != nil else { return nil }
		var mineRoomID: Int?
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.examine(entity: "well") { result in
				let cdTime: Date
				switch result {
				case .success(let examineResponse):
					cdTime = self.dateFromCooldownValue(examineResponse.cooldown)
					if let id = self.getRoomID(from: examineResponse.description) {
						mineRoomID = id
					}
				case .failure(let error):
					print("Error examining well: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
		return mineRoomID
	}

	func examineWellIntelligently() -> Int? {
		var mineRoomID: Int?
		if missedLastSnitch {
			let startValue = examineWell()
			print("missed last snitch - waiting (\(startValue ?? 0))")
			mineRoomID = startValue
			let giveUpWaiting = Date(timeIntervalSinceNow: 15)
			while mineRoomID == startValue && giveUpWaiting > Date() {
				mineRoomID = examineWell()
			}
		} else {
			print("got last snitch!")
			mineRoomID = examineWell()
		}
		return mineRoomID
	}

	func examineBoard() -> [String: Int] {
		guard currentRoom != nil else { return [:] }
		var snitchValues: [String: Int] = [:]
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.examine(entity: "board") { result in
				let cdTime: Date
				switch result {
				case .success(let examineResponse):
					cdTime = self.dateFromCooldownValue(examineResponse.cooldown)
					print(examineResponse.description)
					snitchValues = self.getLeaderBoardInfo(from: examineResponse.description)
				case .failure(let error):
					print("Error examining well: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
		return snitchValues
	}

	func getRoomID(from description: String) -> Int? {
		let ls8 = LS8Cpu()
		let data = DataConvert.binStringToData(description)
		ls8.load(program: data)
		guard let trail = ls8.run().split(separator: " ").last else { return nil }
		let strNum = String(trail)

		return Int(strNum)
	}

	func getLeaderBoardInfo(from description: String) -> [String: Int] {
//		1. 5653 - mrpizza
//		2. 270 - Krishan the Quail
//		...

		// split into lines
		let lines = description.split(separator: "\n").map { String($0) }
		// remove leading rank value
		let removeRank = lines.map { $0.replacingOccurrences(of: ##"\d+\. "##, with: "", options: .regularExpression, range: nil) }
		// split on spaces. results should be like [["323", "-", "name"], ...]
		let splits = removeRank.map { $0.split(separator: " ").compactMap { String($0) } }

		var leaderboard = [String: Int]()
		for splitLine in splits {
			guard let snitchCount = Int(splitLine[0]) else { continue }
			leaderboard[splitLine[2]] = snitchCount
		}
		return leaderboard
	}

	func getPlayerStatus() {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.playerStatus { result in
				let cdTime: Date
				switch result {
				case .success(let playerInfo):
					cdTime = self.dateFromCooldownValue(playerInfo.cooldown)
					self.playerStatus = playerInfo
					print(playerInfo)
				case .failure(let error):
					print("Error updating status: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func equip(item: String) {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.equip(item: item) { result in
				let cdTime: Date
				switch result {
				case .success(let playerInfo):
					cdTime = self.dateFromCooldownValue(playerInfo.cooldown)
					print(playerInfo)
				case .failure(let error):
					print("Error equipping item: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func unequip(item: String) {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.unequip(item: item) { result in
				let cdTime: Date
				switch result {
				case .success(let playerInfo):
					cdTime = self.dateFromCooldownValue(playerInfo.cooldown)
					print(playerInfo)
				case .failure(let error):
					print("Error unequipping item: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func changeName(to name: String, confirm: Bool) {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.changeName(newName: name, confirm: confirm) { result in
				let cdTime: Date
				switch result {
				case .success(let roomInfo):
					cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
					print(roomInfo)
				case .failure(let error):
					print("Error changing name: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func pray() {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.pray { result in
				let cdTime: Date
				switch result {
				case .success(let roomInfo):
					cdTime = self.dateFromCooldownValue(roomInfo.cooldown)
					print(roomInfo)
				case .failure(let error):
					print("Error praying: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func ghostCarry(item: String) {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.ghostCarry(item: item) { result in
				let cdTime: Date
				switch result {
				case .success(let playerResponse):
					cdTime = self.dateFromCooldownValue(playerResponse.cooldown)
					print(playerResponse)
				case .failure(let error):
					print("Error ghosting item: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func ghostReceive(item: String) {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.ghostReceive(item: item) { result in
				let cdTime: Date
				switch result {
				case .success(let playerResponse):
					cdTime = self.dateFromCooldownValue(playerResponse.cooldown)
					print(playerResponse)
				case .failure(let error):
					print("Error unghosting item: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func transmog(item: String) {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.transmog(item: item) { result in
				let cdTime: Date
				switch result {
				case .success(let playerResponse):
					cdTime = self.dateFromCooldownValue(playerResponse.cooldown)
					print(playerResponse)
				case .failure(let error):
					print("Error transmogging item: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func foundItems() {
		print("Note, these may have been picked up!")
		let roomsWithItems = rooms.filter { ($0.value.items?.count ?? 0) > 0 }
		roomsWithItems.forEach { print("Room \($0.key) has \($0.value.items ?? [])") }
	}

	func getSnitchCount() {
		if playerStatus == nil {
			getPlayerStatus()
		}
		try? go(to: 986, quietly: true)
		let leaderboard = examineBoard()
		if let playerName = playerStatus?.name, let myEntry = leaderboard[playerName] {
			snitchCount = myEntry
		}
	}

	// MARK: - Mining

	private var lastProof: LastProof?
	private var lastProofTime: Date?
	func getLastProof() {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.getLastProof { result in
				let cdTime: Date
				switch result {
				case .success(let lastProof):
					cdTime = self.dateFromCooldownValue(lastProof.cooldown)
					self.lastProof = lastProof
					self.lastProofTime = Date()
					print(lastProof)
				case .failure(let error):
					print("Error getting proof: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func mine() {
		if lastProof == nil {
			getLastProof()
		}
		guard let lastProof = lastProof else { return }
		let coinminer = CoinMiner(lastProof: lastProof, iterations: 99999)

		var proof: Int?

		while proof == nil {
			print("mining")
			if let lastProofTime = lastProofTime, lastProofTime.addingTimeInterval(10) < Date() {
				getLastProof()
				coinminer.lastProof = self.lastProof ?? coinminer.lastProof
			}
			DispatchQueue.concurrentPerform(iterations: 4) { _ in
				if let newProof = coinminer.mine() {
					proof = newProof
				}
			}
			if let foundProof = proof {
				let success = submitProof(proof: foundProof)
				proof = success ? proof : nil
			}
		}
	}

	func autoMine() {
		while true {
			do {
				try go(to: 55, quietly: true)
				guard let mineRoomID = examineWell() else { continue }
				print("Heading to room \(mineRoomID) for mining")
				try go(to: mineRoomID, quietly: true)
				mine()
				getBalance()
				sellAllItems()
			} catch {
				print("There was an error automining: \(error)")
			}
		}
	}

	private func submitProof(proof: Int) -> Bool {
		var success = false
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.submitProof(proof: proof) { result in
				let cdTime: Date
				switch result {
				case .success(let submissionResult):
					cdTime = self.dateFromCooldownValue(submissionResult.cooldown)
					print(submissionResult)
					success = true
				case .failure(let error):
					print("Error submitting proof: \(error)")
					cdTime = self.cooldownFromError(error)
					success = false
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
		return success
	}

	func getBalance() {
		guard currentRoom != nil else { return }
		commandQueue.addCommand { dateCompletion in
			self.apiConnection.getBalance { result in
				let cdTime: Date
				switch result {
				case .success(let balanceInfo):
					cdTime = self.dateFromCooldownValue(balanceInfo.cooldown)
					print(balanceInfo)
				case .failure(let error):
					print("Error getting balance: \(error)")
					cdTime = self.cooldownFromError(error)
				}
				dateCompletion(cdTime)
			}
		}
		waitForCommandQueue()
	}

	func snitchMining() {
		guard currentRoom != nil else { return }
		getPlayerStatus()
		buyDonutIfNeeded()
		getSnitchCount()
		while (snitchCount ?? 0) < Int.max {
			do {
				buyDonutIfNeeded()
				if (playerStatus?.gold ?? 0) < 4500 { // 4500 is a good starting value
					gatherTreasure()
					sellAllItems()
					continue
				}
				try go(to: 555, quietly: true)
				guard let mineRoomID = examineWellIntelligently() else { continue }
				goalSnitchRoom = mineRoomID
				print("\nHeading to room \(mineRoomID) for snitching!\n")
				try go(to: mineRoomID, quietly: true)
				sellAllItems()
				//				recall()
			} catch {
				print("There was an error snitchmining: \(error)")
			}
		}
	}

	private func buyDonutIfNeeded() {
		if (playerStatus?.gold ?? 0) > 2000 {
			if sugarRushExpiration == nil {
				print("no sugar rush!")
				buyDonut()
			} else if let exp = sugarRushExpiration, Date() > exp {
				print("sugar rush almost done!")
				buyDonut()
			}
		}
	}

	func wanderInDarkWorld() {
		guard let currentRoom = currentRoom else { return }
		if currentRoom < 500 {
			warp()
		}

		while true {
			let randomRoom = Int.random(in: 500..<1000)
			do {
				try go(to: randomRoom, quietly: true)
			} catch {
				print("Error wandering to room:\(randomRoom)")
			}
		}
	}

	func treasureHunt() {
		guard currentRoom != nil else { return }
		getPlayerStatus()

		while true {
			if (playerStatus?.gold ?? 0) > 2000 {
				if sugarRushExpiration == nil {
					buyDonut()
				} else if let exp = sugarRushExpiration, Date() > exp {
					buyDonut()
				}
			}
			gatherTreasure()
			sellAllItems()
		}
	}

	// MARK: - Path calculation
	/// Performs a breadth first search to get from start to destination
	@available(*, deprecated, message: "Use `shortestRoutes` instead.")
	func shortestRoute(from startRoomID: Int, to destinationRoomID: Int) throws -> [PathElement<Direction>] {
		guard rooms[startRoomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: startRoomID) }
		guard rooms[destinationRoomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: destinationRoomID) }

		let queue = Queue<[PathElement<Direction?>]>()
		queue.enqueue([PathElement(direction: nil, roomID: startRoomID)])
		var visited = Set<Int>()

		while queue.count > 0 {
			guard let path = queue.dequeue() else { continue }
			guard let lastPathElement = path.last else { continue }
			let endRoomID = lastPathElement.roomID
			if endRoomID == destinationRoomID {
				return path.compactMap {
					guard let direction = $0.direction else { return nil }
					return PathElement(direction: direction, roomID: $0.roomID)
				}
			}
			guard !visited.contains(endRoomID) else { continue }
			visited.insert(endRoomID)
			guard let endRoom = rooms[endRoomID] else { continue }
			for (direction, connectedRoomID) in endRoom.connections {
				var newPath = path
				newPath.append(PathElement(direction: direction, roomID: connectedRoomID))
				queue.enqueue(newPath)
			}
			// add warp room to shortest path
			var warpRoom: Int
			switch endRoom.id {
			case 0...499:
				warpRoom = endRoom.id + 500
			default:
				warpRoom = endRoom.id - 500
			}
			var newPath = path
			newPath.append(PathElement(direction: .warp, roomID: warpRoom))
			queue.enqueue(newPath)

			// add recall room to shortest path
			guard path.last?.roomID != 0 else { continue }
			newPath = path
			newPath.append(PathElement(direction: .recall, roomID: 0))
			queue.enqueue(newPath)
		}
		throw RoomControllerError.pathNotFound
	}

	/// Instead of just a breadth first search, performs a breadth first traversal, comparing potential paths for the fastest one.
	func shortestRoutes(from startRoomID: Int, to destinationRoomID: Int) throws -> [MovementType] {
		guard rooms[startRoomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: startRoomID) }
		guard rooms[destinationRoomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: destinationRoomID) }

		let queue = Queue<[PathElement<Direction?>]>()
		queue.enqueue([PathElement(direction: nil, roomID: startRoomID)])
		var visited = Set<Int>()

		var paths = [(cost: Double, path: [MovementType])]()

		while queue.count > 0 {
			guard let path = queue.dequeue() else { continue }
			guard let lastPathElement = path.last else { continue }
			let endRoomID = lastPathElement.roomID
			if endRoomID == destinationRoomID {
				let fullPath: [PathElement<Direction>] = path.compactMap {
					guard let direction = $0.direction else { return nil }
					return PathElement(direction: direction, roomID: $0.roomID)
				}
				let movementPath = fullPath.poweredUp(rooms: rooms)
				let cost = movementPath.totalApproxCost(rooms: rooms)

				paths.append((cost, movementPath))
				continue
			}
			guard !visited.contains(endRoomID) else { continue }
			visited.insert(endRoomID)
			guard let endRoom = rooms[endRoomID] else { continue }
			for (direction, connectedRoomID) in endRoom.connections {
				var newPath = path
				newPath.append(PathElement(direction: direction, roomID: connectedRoomID))
				queue.enqueue(newPath)
			}
			// add warp room to shortest path
			var warpRoom: Int
			switch endRoom.id {
			case 0...499:
				warpRoom = endRoom.id + 500
			default:
				warpRoom = endRoom.id - 500
			}
			var newPath = path
			newPath.append(PathElement(direction: .warp, roomID: warpRoom))
			queue.enqueue(newPath)

			// add recall room to shortest path
			guard path.last?.roomID != 0 else { continue }
			newPath = path
			newPath.append(PathElement(direction: .recall, roomID: 0))
			queue.enqueue(newPath)
		}

		paths.sort { $0.cost < $1.cost }
//		paths.forEach { print($0) }
		return paths.first?.path ?? []
	}

	func nearestUnexplored(from startRoomID: Int) throws -> [PathElement<Direction>] {
		guard rooms[startRoomID] != nil else { throw RoomControllerError.roomDoesntExist(roomID: startRoomID) }

		let queue = Queue<[PathElement<Direction?>]>()
		queue.enqueue([PathElement(direction: nil, roomID: startRoomID)])
		var visited = Set<Int>()

		while queue.count > 0 {
			guard let path = queue.dequeue() else { continue }
			guard let lastPathElement = path.last else { continue }
			let endRoomID = lastPathElement.roomID
			guard !visited.contains(endRoomID) else { continue }
			visited.insert(endRoomID)

			guard let endRoom = rooms[endRoomID] else { continue }
			if endRoom.unknownConnections.count > 0 {
				return path.compactMap {
					guard let direction = $0.direction else { return nil }
					return PathElement(direction: direction, roomID: $0.roomID)
				}
			}
			for (direction, connectedRoomID) in endRoom.connections {
				var newPath = path
				newPath.append(PathElement(direction: direction, roomID: connectedRoomID))
				queue.enqueue(newPath)
			}
		}
		throw RoomControllerError.pathNotFound
	}

	// double while loop over the path, first iterating each element, then the next loop looking forward until there's a different direction. condense somehow
//	func compactForDash(path: []) -> [PathElement]

	func explore() throws {
		stopExploring = false
		while !stopExploring {
			guard var currentRoom = currentRoom else { return }
			let pathToNearestUnexplored = try nearestUnexplored(from: currentRoom)
			if let lastElement = pathToNearestUnexplored.last {
				print("Room \(lastElement.roomID) still has unexplored rooms. Headed there now!\n\n")
				try go(to: lastElement.roomID, quietly: false)
				currentRoom = lastElement.roomID
			}

			if rooms.count.isMultiple(of: 5) {
				drawMap()
			}

			guard let room = rooms[currentRoom] else { return }
			guard let direction = room.unknownConnections.first else { continue }
			if room.terrain == "CAVE" {
				move(in: direction) { _ in
					print("Checked out a new room...\n\n")
				}
			} else {
				fly(in: direction) { _ in
					print("Checked out a new room...\n\n")
				}
			}
		}
	}

	// MARK: - logging
	private func logRoomInfo(_ roomInfo: RoomResponse, movedInDirection direction: Direction?, dashed: Bool = false) {
		previousRoomID = currentRoom
		currentRoom = roomInfo.roomID

		updateRoom(from: roomInfo, room: roomInfo.roomID)
		if rooms[roomInfo.roomID] == nil {
			let room = RoomLog(id: roomInfo.roomID,
							   title: roomInfo.title,
							   description: roomInfo.description,
							   location: roomInfo.coordinates,
							   elevation: roomInfo.elevation,
							   terrain: roomInfo.terrain,
							   items: roomInfo.items,
							   messages: Set(roomInfo.messages))
			rooms[roomInfo.roomID] = room
			roomInfo.exits.forEach {
				guard let unknownDirection = Direction(rawValue: $0) else { return }
				room.unknownConnections.insert(unknownDirection)
			}
		}
		guard let room = rooms[roomInfo.roomID] else { return }

		if let previousRoomID = previousRoomID, let direction = direction, !dashed {
			guard let previousRoom = rooms[previousRoomID] else { fatalError("Previous room: \(previousRoomID) not logged!") }
			connect(previousRoom: previousRoom, newRoom: room, direction: direction)
		}
		simpleSaveToPersistentStore()
	}

	private func updateMessages(_ messages: [String], forRoom roomID: Int) {
		let newMessages = Set(messages)
		rooms[roomID]?.messages.formUnion(newMessages)

		newMessages.forEach {
			if $0.contains("your hand closes around the snitch") {
				snitchCount = snitchCount.map { $0 + 1 } // snitchCount += 1 (cuz optional)
				print("\n\nsnitch count: \(snitchCount ?? 0)\n\n")
			}
		}
	}

	private func updateRoom(from info: RoomResponse, room: Int) {
		updateMessages(info.messages, forRoom: room)
		rooms[room]?.title = info.title
		rooms[room]?.description = info.description
		rooms[room]?.items = info.items
		if (info.items?.count ?? 0) > 0 {
			print("Room: \(room) items: \(info.items ?? [])")
		}
		if (info.players?.count ?? 0) > 0 {
			print("Room: \(room) players: \(info.players ?? [])")
		}


		if info.items?.contains("golden snitch") == true {
			jumpTake(item: "golden snitch")
		}

		if info.roomID == goalSnitchRoom {
			if info.messages.contains("A great warmth floods your body as your hand closes around the snitch before it vanishes.") {
				missedLastSnitch = false
			} else {
				missedLastSnitch = true
			}
		}

		let roomItems = info.items ?? []
		if info.roomID < 500 && roomItems.count > 0 {
			jumpTake(item: roomItems.first!)
		}
	}

	private func connect(previousRoom: RoomLog, newRoom: RoomLog, direction: Direction) {
		guard previousRoom != newRoom else { return }
		// double check direction and positions match (this might not be necessary, but just verifying)
		switch direction {
		case .north:
			precondition(previousRoom.location.x == newRoom.location.x)
			precondition(previousRoom.location.y + 1 == newRoom.location.y)
		case .south:
			precondition(previousRoom.location.x == newRoom.location.x)
			precondition(previousRoom.location.y == newRoom.location.y + 1)
		case .west:
			precondition(previousRoom.location.x == newRoom.location.x + 1)
			precondition(previousRoom.location.y == newRoom.location.y)
		case .east:
			precondition(previousRoom.location.x + 1 == newRoom.location.x)
			precondition(previousRoom.location.y == newRoom.location.y)
		case .warp:
			return
		case .recall:
			return
		}

		connectOneWay(startingIn: previousRoom, endingIn: newRoom, direction: direction)
		connectOneWay(startingIn: newRoom, endingIn: previousRoom, direction: direction.opposite)
	}

	private func connectOneWay(startingIn previousRoom: RoomLog, endingIn newRoom: RoomLog, direction: Direction) {
		if previousRoom.connections[direction] != nil && previousRoom.connections[direction] != newRoom.id {
			fatalError("Room \(previousRoom.id) is already connected to \(previousRoom.connections[direction] ?? -1) in that direction! \(direction). Attempted to connect to \(newRoom.id)")
		}
		previousRoom.connections[direction] = newRoom.id
		previousRoom.unknownConnections.remove(direction)
	}

	// MARK: - Visual
	func drawMap() {
		drawMap(world: 0)
		drawMap(world: 1)
	}

	func drawMap(world: Int) {
		let worldRange = (500 * world)..<(500 * (world + 1))
		let worldRooms = rooms.filter { worldRange.contains($0.key) }

		print("\nWorld \(world + 1)")

		let size = worldRooms.reduce(RoomLocation(x: 0, y: 0)) {
			RoomLocation(x: max($0.x, $1.value.location.x), y: max($0.y, $1.value.location.y))
		}

		let row = (0...size.x).map { _ in " " }
		var matrix = (0...size.y).map { _ in row }

		for (_, room) in worldRooms {
			let location = room.location
			var char = room.unknownConnections.isEmpty ? "+" : "?"
			char = room.id == 0 ? "O" : char
			char = room.id == 1 ? "S" : char
			char = room.id == 55 ? "W" : char
			char = room.terrain == "TRAP" ? "!" : char

//			while char.count < 5 {
//				char = " \(char) "
//			}
//			while char.count > 5 {
//				char.removeLast()
//			}

			matrix[location.y][location.x] = char
		}

		let flipped = matrix.reversed()

		let strings = flipped.map { $0.joined(separator: "") }

		for row in strings {
			guard row.contains(where: { character -> Bool in
				character != " "
			}) else { continue }
			print(row)
		}
	}

	// MARK: - Wait functions
	private func waitForCommandQueue() {
		var printedNotice = false
		var lastTimeNotice = Date(timeIntervalSinceNow: -1)
		while commandQueue.commandCount > 0 || commandQueue.currentlyExecuting {
			if !printedNotice {
				print("waiting for command queue to finish...", terminator: "")
				printedNotice = true
			}
			if lastTimeNotice.addingTimeInterval(1) < Date() {
				lastTimeNotice = Date()
				let difference = Int(commandQueue.earliestNextCommand.timeIntervalSince1970 - lastTimeNotice.timeIntervalSince1970)
				print(difference, terminator: difference > 0 ? " " : "\n")
			}
			usleep(10000)
		}
	}

	private func waitForCooldownQueue() {
		var printedNotice = false
		var lastTimeNotice = Date(timeIntervalSinceNow: -1)
		while cdCommandQueue.currentlyExecuting {
			if !printedNotice {
				print("waiting for command queue to finish...", terminator: "")
				printedNotice = true
			}
			if lastTimeNotice.addingTimeInterval(0.25) < Date() {
				lastTimeNotice = Date()
				let cdRemaining = cdCommandQueue.cooldownRemaining
				let cdRemainingStr = String(format: "%.02f", cdRemaining)
				print(cdRemainingStr, terminator: cdRemaining > 0 ? " " : "\n")
			}
			usleep(10000)
		}
	}

	private func dateFromCooldownValue(_ cooldown: TimeInterval) -> Date {
		Date(timeIntervalSinceNow: cooldown + 0.01)
	}

	private func cooldownDurationFromError(_ error: Error) -> TimeInterval {
		guard let error = error as? NetworkError else { return 0 }

		let returnedData: Data?
		switch error {
		case .badData(sourceData: let data):
			returnedData = data
		case .dataCodingError(specifically: _, sourceData: let data):
			returnedData = data
		case .httpNon200StatusCode(code: _, data: let data):
			returnedData = data
		default:
			return 0
		}

		guard let data = returnedData, let genericResponse = try? JSONDecoder().decode(BasicResponse.self, from: data) else { return 0 }
		return genericResponse.cooldown
	}

	private func cooldownFromError(_ error: Error) -> Date {
		return dateFromCooldownValue(cooldownDurationFromError(error))
	}

	// MARK: - Persistence
	private func getFilePaths() throws -> (plistFile: File, jsonFile: File) {
		let folder = try Folder
			.home
			.createSubfolderIfNeeded(withName: "Documents")
			.createSubfolderIfNeeded(withName: "MUDmap")

		let plistFile = try folder.createFileIfNeeded(withName: "map.plist")
		let jsonFile = try folder.createFileIfNeeded(withName: "map.json")
		return (plistFile, jsonFile)
	}

	private func simpleLoadFromPersistentStore() {
		do {
			try loadFromPersistentStore()
		} catch {
			print("Error loading data from plist: \(error)")
		}
	}

	private func loadFromPersistentStore() throws {
		let (plistPath, _) = try getFilePaths()
		let plistData = try plistPath.read()
		rooms = try PropertyListDecoder().decode([Int: RoomLog].self, from: plistData)
	}

	private func simpleSaveToPersistentStore() {
		do {
			try saveToPersistentStore()
		} catch {
			print("Error saving data: \(error)")
		}
	}

	private func saveToPersistentStore() throws {
		let (plistOut, jsonOut) = try getFilePaths()

		let plistData = try PropertyListEncoder().encode(rooms)
		let jsonEnc = JSONEncoder()
		jsonEnc.keyEncodingStrategy = .convertToSnakeCase
		if #available(OSX 10.13, *) {
			jsonEnc.outputFormatting = [.prettyPrinted, .sortedKeys]
		} else {
			jsonEnc.outputFormatting = [.prettyPrinted]
		}
		let jsonData = try jsonEnc.encode(rooms)

		try plistOut.write(plistData)
		try jsonOut.write(jsonData)
	}
}

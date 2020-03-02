//
//  File.swift
//  
//
//  Created by Michael Redig on 3/1/20.
//

import Foundation

class CommandQueue {

	private(set) var currentlyExecuting = false

	private let internalCommandQueue = DispatchQueue(label: "internal command queue")
	private var _commands = Queue<(@escaping (Date) -> Void) -> Void>()
	private(set) var commands: Queue<(@escaping (Date) -> Void) -> Void> {
		get { internalCommandQueue.sync { _commands } }
		set { internalCommandQueue.sync { _commands = newValue } }
	}


	var commandCount: Int { commands.count }
	private(set) var earliestNextCommand = Date()

	private let opQueue = DispatchQueue(label: "This Command Queue!")

	func addCommand(_ command: @escaping (@escaping (Date) -> Void) -> Void) {
		commands.enqueue(command)
	}

	private var started = false
	func start() {
		guard !started else { return }
		started = true
		opQueue.async {
			while true {
				guard self.commandLoop() else {
					usleep(10000)
					continue
				}
			}
		}
	}

	func updateCooldown(_ date: Date) {
		earliestNextCommand = date
		currentlyExecuting = false
	}

	private func commandLoop() -> Bool {
		guard !currentlyExecuting, Date() > earliestNextCommand, commandCount > 0 else { return false }
		guard let command = commands.dequeue() else { return false }
		currentlyExecuting = true
		command(updateCooldown)
		return true
	}
}

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
	/// Used to provide the timestamp that the most recent cooldown expires
	typealias DateCompletionHandler = (Date) -> Void
	/// Type used to do an arbitrary task, typically involving a cooldown. Will complete the task, requiring that the
	/// `DateCompletionHandler` is called, passing in the next time a command may run.
	typealias QueuedCommand = (@escaping DateCompletionHandler) -> Void
	private var _commands = Queue<QueuedCommand>()
	private(set) var commands: Queue<QueuedCommand> {
		get { internalCommandQueue.sync { _commands } }
		set { internalCommandQueue.sync { _commands = newValue } }
	}


	var commandCount: Int { commands.count }
	private(set) var earliestNextCommand = Date()

	private let opQueue = DispatchQueue(label: "This Command Queue!")

	/// adds an arbitrary command closure to the queue. They will be completed in the order they are added, waiting for
	/// cooldowns to finish in between.
	func addCommand(_ command: @escaping QueuedCommand) {
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

	private func updateCooldown(_ date: Date) {
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

	func jumpQueue(_ command: @escaping QueuedCommand) {
		commands.jumpQueue(command)
	}
}

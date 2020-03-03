//: Playground - noun: a place where people can play
import Foundation

enum Direction: String, Codable, Hashable {
	case north = "n"
	case south = "s"
	case east = "e"
	case west = "w"

	var opposite: Direction {
		switch self {
		case .north:
			return .south
		case .south:
			return .north
		case .west:
			return .east
		case .east:
			return .west
		}
	}
}

struct DirectionWrapper: Codable {
	let direction: Direction
	let nextRoomID: String?
}

struct DashWrapper: Codable {
	let direction: Direction
	let numRooms: String
	let nextRoomIds: String
}

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


class RoomLog: Codable, Equatable {
	static func == (lhs: RoomLog, rhs: RoomLog) -> Bool {
		lhs.id == rhs.id &&
		lhs.location == rhs.location &&
		lhs.connections == rhs.connections
	}

	let id: Int
	var title: String
	var description: String
	let location: RoomLocation
	var connections: [Direction: Int]
	var unknownConnections = Set<Direction>()
	let elevation: Double?
	let terrain: String?
	var items: [String]?
	var messages: Set<String>

	init(id: Int, title: String, description: String, location: RoomLocation, elevation: Double?, terrain: String?, items: [String]?, messages: Set<String>) {
		self.id = id
		self.location = location
		connections = [Direction: Int]()
		self.elevation = elevation
		self.terrain = terrain
		self.items = items
		self.title = title
		self.description = description
		self.messages = messages
	}
}


let path = "/Users/mredig/Documents/MUDmap/map.plist"
let url = URL(fileURLWithPath: path)

let data = try! Data(contentsOf: url)

let json = try! PropertyListDecoder().decode([Int: RoomLog].self, from: data)

var descDict = [String: (Int, String)]()

let meh = Set([
	"You are standing on grass and surrounded by a dense mist. You notice a cave entrance to the east and cliffside landmark to the west.",
	"You are standing in the center of a brightly lit room. You notice a shop to the west and exits to the north, south and east.",
	"You are standing in a dark cave.",
	"You see a moss-topped gravestone which reads: \'Here lies Glasowyn of Web17/Labs12/CS18, who was crushed under the weight of her own gold.\' There doesn\'t seem to be any gold around, but marks in the dirt suggest that someone has knelt there, perhaps in prayer.",
	"You are on the side of a steep incline.",
	"You are at the base of a large, looming mountain.",
	"You are standing on grass and surrounded by a dense mist. You can barely make out the exits in any direction.",
	"You are standing on grass and surrounded by darkness."
])

for (id, room) in json {
	guard !meh.contains(room.description) else { continue }
	descDict[room.description] = (id, room.title)
}

let descs = descDict.map { ($0.value, $0.key) }.sorted { (a, b) -> Bool in
	a.0.0 < b.0.0
}

for desc in descs {
	print("\(desc.0): ")
	print("\t\(desc.1)\n")
//	print(desc)
}

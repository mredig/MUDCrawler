// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "MUDCrawler",
	platforms: [
		.macOS(.v10_15),
	],
	products: [
		// Products define the executables and libraries produced by a package, and make them visible to other packages.
		.library(
			name: "MUDCrawlerCore",
			targets: ["MUDCrawlerCore"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/johnsundell/files.git", from: "4.0.0"),
		.package(url: "https://github.com/mredig/NetworkHandler.git", from: "0.9.7"),
		.package(url: "https://github.com/mredig/LS8Swift.git", from: "0.0.1"),
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0")

	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(name: "MUDCrawlerCore",
				dependencies: [
					"Files",
					"NetworkHandler",
					"LS8Core",
					"CryptoSwift"
		]),
		.target(
			name: "MUDCrawler",
			dependencies: ["MUDCrawlerCore"]),

		.testTarget(
			name: "MUDCrawlerTests",
			dependencies: ["MUDCrawlerCore"]),
	]
)

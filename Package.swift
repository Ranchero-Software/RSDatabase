// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "RSDatabase",
	platforms: [.macOS(.v10_15), .iOS(.v13)],
	products: [
        .library(
            name: "RSDatabase",
            type: .dynamic,
            targets: ["RSDatabase"]),
		.library(
			name: "RSDatabaseObjC",
			type: .dynamic,
			targets: ["RSDatabaseObjC"]),
    ],
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RSDatabase",
            dependencies: ["RSDatabaseObjC"]
		),
		.target(
			name: "RSDatabaseObjC",
			dependencies: []
		),
        .testTarget(
            name: "RSDatabaseTests",
            dependencies: ["RSDatabase"]
		),
    ]
)

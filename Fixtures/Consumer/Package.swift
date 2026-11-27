// swift-tools-version: 6.0

import PackageDescription

// A package that uses DMCore the way a library of the family does. It exists to be compiled: when
// a public declaration it uses changes shape, it stops building.
let package = Package(
    name: "Consumer",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v13)],
    products: [
        .library(name: "Consumer", targets: ["Consumer", "ConsumerTesting"])
    ],
    dependencies: [
        .package(name: "DMCore", path: "../..")
    ],
    targets: [
        // A library. It depends on DMCore alone: the rejected shapes check that it reaches no test
        // double.
        .target(
            name: "Consumer",
            dependencies: [.product(name: "DMCore", package: "DMCore")]
        ),
        // The code of its tests, which adds DMCoreTesting. It builds with ExistentialAny, the
        // setting DMCore itself builds with; the library above builds without it.
        .target(
            name: "ConsumerTesting",
            dependencies: [
                "Consumer",
                .product(name: "DMCore", package: "DMCore"),
                .product(name: "DMCoreTesting", package: "DMCore")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        )
    ]
)

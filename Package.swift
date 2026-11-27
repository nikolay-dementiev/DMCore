// swift-tools-version: 6.0
// 6.0 is the oldest tools version among the libraries of the family that will use this package.
import PackageDescription

let swiftSettings: [SwiftSetting] = [.enableUpcomingFeature("ExistentialAny")]

let package = Package(
    name: "DMCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        // The package builds on the Mac too. The floor is for the planned tracing kit:
        // OSSignposter needs macOS 12, OSAllocatedUnfairLock needs macOS 13.
        .macOS(.v13),
    ],
    products: [
        .library(name: "DMCore", targets: ["DMCore"]),
        .library(name: "DMCoreTesting", targets: ["DMCoreTesting"]),
    ],
    targets: [
        .target(name: "DMCore", swiftSettings: swiftSettings),
        .target(name: "DMCoreTesting", dependencies: ["DMCore"], swiftSettings: swiftSettings),
        .testTarget(
            name: "DMCoreTests",
            dependencies: ["DMCore", "DMCoreTesting"],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)

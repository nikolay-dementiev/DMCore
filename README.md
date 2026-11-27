# DMCore

The small runtime core of the DM Swift SDK family.

[![CI](https://github.com/nikolay-dementiev/DMCore/actions/workflows/ci.yml/badge.svg)](https://github.com/nikolay-dementiev/DMCore/actions/workflows/ci.yml)

DMCore holds the tracing kit that the libraries of the family share. A library tells a performance
tool about its own work through `Tracing`: it begins and ends intervals and emits events.
`SystemTracing` records them as signposts of the system, and `NoTracing` records nothing. A test
passes `TracingSpy`, of the product `DMCoreTesting`, and reads back what the library did.

It needs iOS 17, watchOS 10 or macOS 13, and Swift 6.2, which Xcode 26 or later brings. It has no
dependency.

## Installation

DMCore is a Swift package. Add it and its product to your `Package.swift`, and the product
`DMCoreTesting` to the target that tests your code:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyLibrary",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v13)],
    products: [
        .library(name: "MyLibrary", targets: ["MyLibrary"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nikolay-dementiev/DMCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MyLibrary",
            dependencies: [.product(name: "DMCore", package: "DMCore")]
        ),
        .testTarget(
            name: "MyLibraryTests",
            dependencies: [
                "MyLibrary",
                .product(name: "DMCoreTesting", package: "DMCore"),
            ]
        ),
    ]
)
```

There is no CocoaPods distribution.

## Documentation

- [The interface and its rules](Sources/DMCore/DMCore.docc/DMCore.md): how a library takes a
  tracing value, how it names its signposts and what a detail may hold.
- [Seeing the signposts](Sources/DMCore/DMCore.docc/SeeingSignposts.md): how to record them with
  Instruments or `xctrace`.

Both are pages of the DocC documentation, which Xcode builds with Product, Build Documentation.

## The family

- [DMAction](https://github.com/nikolay-dementiev/DMAction): completion-based actions with retry and
  fallback.
- [DMVariableBlurView](https://github.com/nikolay-dementiev/DMVariableBlurView): a blur whose
  radius changes from row to row.
- [DMUnLoader](https://github.com/nikolay-dementiev/DMUnLoader): a HUD for the loading, success and
  failure states of an iOS app.
- [DMDevKit](https://github.com/nikolay-dementiev/DMDevKit): the development and CI tooling of the
  libraries. It is not linked into apps.

## Contributing, security, license

- [CONTRIBUTING.md](CONTRIBUTING.md): how to build, check, release and propose a change.
- [ENGINEERING.md](ENGINEERING.md): the architecture and the compatibility policy.
- [CHANGELOG.md](CHANGELOG.md): what changed.
- [SECURITY.md](SECURITY.md): how to report a vulnerability.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md): how people treat each other here.

MIT license. See [LICENSE](LICENSE).

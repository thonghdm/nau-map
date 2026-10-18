// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NaumapCore",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "NaumapCore",
            targets: ["NaumapCore"]
        )
    ],
    dependencies: [
        // SQLite WAL Mode & R*Tree support for spatial alerts
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0")
    ],
    targets: [
        .target(
            name: "NaumapCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/NaumapCore"
        ),
        .testTarget(
            name: "NaumapCoreTests",
            dependencies: ["NaumapCore"],
            path: "Tests/NaumapCoreTests"
        )
    ]
)

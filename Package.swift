// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var packageDependencies: [Package.Dependency] = []
var coreDependencies: [Target.Dependency] = []

#if !os(Windows)
packageDependencies = [
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0")
]
coreDependencies = [
    .product(name: "GRDB", package: "GRDB.swift")
]
#endif

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
    dependencies: packageDependencies,
    targets: [
        .target(
            name: "NaumapCore",
            dependencies: coreDependencies,
            path: "Sources/NaumapCore"
        ),
        .testTarget(
            name: "NaumapCoreTests",
            dependencies: ["NaumapCore"],
            path: "Tests/NaumapCoreTests"
        )
    ]
)

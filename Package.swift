// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftCST",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftCST",
            targets: ["SwiftCST"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/tonytins/future-foundations", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftCST",
            dependencies: [
                .product(name: "FutureFoundations", package: "future-foundations"),
            ]
        ),
        .testTarget(
            name: "SwiftCSTTests",
            dependencies: ["SwiftCST"],
        ),
    ],
    swiftLanguageModes: [.v6],
)

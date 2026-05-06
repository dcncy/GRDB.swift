// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GRDB",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "GRDB", targets: ["GRDB", "_GRDBDummy"]),
    ],
    targets: [
        .binaryTarget(
            name: "GRDB",
            url: "https://github.com/dcncy/GRDB.swift/releases/download/3.1.0/GRDB.xcframework.zip",
            checksum: "ddcdbf92c9147183b20e2deca9888993289b2ed25024711d446a8e11efc17a7b"
        ),
        .target(name: "_GRDBDummy")
    ]
)

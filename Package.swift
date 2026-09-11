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
            url: "https://github.com/dcncy/GRDB.swift/releases/download/3.2.0/GRDB.xcframework.zip",
            checksum: "265837136f90ed655e105111ec16edd379d2c607aed8bbbc1fb25607a74c923c"
        ),
        .target(name: "_GRDBDummy")
    ]
)

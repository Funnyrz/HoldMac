// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HoldMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "HoldMac", targets: ["HoldMac"])
    ],
    targets: [
        .executableTarget(
            name: "HoldMac",
            path: "Sources/HoldMac"
        ),
        .testTarget(
            name: "HoldMacTests",
            dependencies: ["HoldMac"],
            path: "Tests/HoldMacTests"
        )
    ]
)

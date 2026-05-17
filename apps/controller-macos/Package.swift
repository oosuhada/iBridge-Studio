// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iBridgeController",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "iBridgeController", targets: ["iBridgeController"])
    ],
    targets: [
        .executableTarget(
            name: "iBridgeController",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)

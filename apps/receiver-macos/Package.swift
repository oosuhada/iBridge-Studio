// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iBridgeReceiverMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ibridge-receiver-macos", targets: ["iBridgeReceiverMac"])
    ],
    targets: [
        .executableTarget(
            name: "iBridgeReceiverMac",
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-strict-concurrency=minimal"])
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("VideoToolbox")
            ]
        )
    ]
)

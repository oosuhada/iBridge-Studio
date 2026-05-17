// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iBridgePrimary",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ibridge-primary", targets: ["iBridgePrimary"])
    ],
    targets: [
        .executableTarget(
            name: "iBridgePrimary",
            linkerSettings: [
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("AppKit"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("VideoToolbox")
            ]
        )
    ]
)

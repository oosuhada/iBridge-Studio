// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iBridgePrimary",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ibridge-primary", targets: ["iBridgePrimary"])
    ],
    targets: [
        .executableTarget(
            name: "iBridgePrimary",
            linkerSettings: [
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("VideoToolbox")
            ]
        )
    ]
)

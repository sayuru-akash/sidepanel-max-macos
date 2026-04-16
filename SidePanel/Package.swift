// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SidePanel",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SidePanel",
            path: "SidePanel",
            exclude: [
                "App/Info.plist"
            ]
        )
    ]
)

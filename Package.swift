// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SidePanel",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SidePanel", targets: ["SidePanel"])
    ],
    targets: [
        .executableTarget(
            name: "SidePanel",
            path: "SidePanel",
            exclude: [
                "App/Info.plist",
                "SidePanel.entitlements"
            ]
        ),
        .testTarget(
            name: "SidePanelTests",
            dependencies: ["SidePanel"],
            path: "Tests/SidePanelTests"
        )
    ]
)

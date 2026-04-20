// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnonView",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "AnonView",
            targets: ["AnonView"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "AnonView",
            exclude: ["App/Info.plist"],
            linkerSettings: [
                .unsafeFlags(
                    [
                        "-Xlinker", "-sectcreate",
                        "-Xlinker", "__TEXT",
                        "-Xlinker", "__info_plist",
                        "-Xlinker", "Sources/AnonView/App/Info.plist",
                    ],
                    .when(platforms: [.iOS, .macOS])
                ),
            ]
        ),
        .testTarget(
            name: "AnonViewTests",
            dependencies: ["AnonView"]
        ),
    ]
)

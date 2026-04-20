// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let embeddedInfoPlistPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Sources/AnonView/App/Info.plist")
    .path

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
                        "-Xlinker", embeddedInfoPlistPath,
                    ],
                    .when(platforms: [.iOS, .macOS, .tvOS, .watchOS, .visionOS])
                ),
            ]
        ),
        .testTarget(
            name: "AnonViewTests",
            dependencies: ["AnonView"]
        ),
    ]
)

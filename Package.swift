// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "EvoFoxRoninMac",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "EvoFoxRoninMac",
            targets: ["EvoFoxRoninMac"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "EvoFoxRoninMac",
            dependencies: [],
            path: "Sources/EvoFoxRoninMac",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EvoFoxRoninMacTests",
            dependencies: ["EvoFoxRoninMac"],
            path: "Tests/EvoFoxRoninMacTests",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)

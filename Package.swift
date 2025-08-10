// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VibeCommit",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "VibeCommit", targets: ["VibeCommit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "VibeCommit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            resources: [
                .copy("summarize.py")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Speech"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/VibeCommit/Info.plist"
                ])
            ]
        ),
    ]
)
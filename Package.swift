// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VibeCommit",
    platforms: [.macOS(.v14)],  // macOS 14+ for stability
    products: [
        .executable(name: "VibeCommit", targets: ["VibeCommit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),  // Compatible with 6.2
    ],
    targets: [
        .executableTarget(
            name: "VibeCommit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
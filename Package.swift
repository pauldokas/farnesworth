// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Farnsworth",
    platforms: [
        .iOS(.v17), .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", .upToNextMajor(from: "1.2.0"))
    ],
    products: [
        .library(name: "Farnsworth", targets: ["Farnsworth"])
    ],
    targets: [
        .target(
            name: "Farnsworth",
            dependencies: [
                .product(name: "Atomics", package: "swift-atomics")
            ],
            path: ".",
            exclude: ["AGENTS.md", ".sisyphus", "boulder.json", "project.yml", "Farnsworth.xcodeproj"],
            sources: ["Models", "Audio", "Views", "Store", "FarnsworthApp.swift"]
        )
    ]
)

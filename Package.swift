// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Farnsworth",
    platforms: [
        .iOS(.v17), .macOS(.v14)
    ],
    products: [
        .library(name: "Farnsworth", targets: ["Farnsworth"])
    ],
    targets: [
        .target(
            name: "Farnsworth",
            path: ".",
            exclude: ["AGENTS.md", ".sisyphus", "boulder.json", "project.yml", "Farnsworth.xcodeproj"],
            sources: ["Models", "Audio", "Views", "Store", "FarnsworthApp.swift"]
        )
    ]
)
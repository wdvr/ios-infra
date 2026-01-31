// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnalyticsService",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AnalyticsService",
            targets: ["AnalyticsService"]
        ),
    ],
    dependencies: [
        // Firebase dependencies are optional - apps should add them separately
        // to their project if they want Firebase integration
    ],
    targets: [
        .target(
            name: "AnalyticsService",
            dependencies: [],
            path: "Sources/AnalyticsService"
        ),
        .testTarget(
            name: "AnalyticsServiceTests",
            dependencies: ["AnalyticsService"],
            path: "Tests/AnalyticsServiceTests"
        ),
    ]
)

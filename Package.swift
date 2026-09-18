// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FuzzyBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FuzzyBar",
            path: "Sources/FuzzyBar",
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        ),
        .testTarget(
            name: "FuzzyBarTests",
            dependencies: ["FuzzyBar"],
            path: "Tests/FuzzyBarTests"
        ),
    ]
)

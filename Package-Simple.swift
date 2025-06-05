// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SachelGit",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "sachel", targets: ["SachelGit"])
    ],
    dependencies: [
        // Temporarily removed SwiftGit2 for demo
        .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0")
    ],
    targets: [
        .executableTarget(
            name: "SachelGit",
            dependencies: ["Splash"]
        ),
        .testTarget(
            name: "SachelGitTests",
            dependencies: ["SachelGit"]
        )
    ]
)
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
        .package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "0.10.0"),
        .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0")
    ],
    targets: [
        .executableTarget(
            name: "SachelGit",
            dependencies: ["SwiftGit2", "Splash"]
        ),
        .testTarget(
            name: "SachelGitTests",
            dependencies: ["SachelGit"]
        )
    ]
)
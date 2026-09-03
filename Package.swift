// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "ClaudeSessions",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "ClaudeSessions", path: "Sources/ClaudeSessions")
    ]
)

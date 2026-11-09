// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MemoryBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MemoryBar", targets: ["MemoryBar"]),
        .library(name: "MemoryCore", targets: ["MemoryCore"]),
    ],
    targets: [
        .target(name: "MemoryCore", path: "Sources/MemoryCore"),
        .executableTarget(name: "MemoryBar", dependencies: ["MemoryCore"], path: "Sources/MemoryBar"),
        .testTarget(name: "MemoryCoreTests", dependencies: ["MemoryCore"], path: "Tests/MemoryCoreTests"),
    ]
)

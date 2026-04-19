// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CompanionCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "CompanionCore", targets: ["CompanionCore"]),
        .library(name: "CompanionFeature", targets: ["CompanionFeature"]),
        .executable(name: "CompanionCLI", targets: ["CompanionCLI"]),
        .executable(name: "CompanionDemoApp", targets: ["CompanionDemoApp"])
    ],
    targets: [
        .target(name: "CompanionCore"),
        .target(name: "CompanionFeature", dependencies: ["CompanionCore"]),
        .executableTarget(name: "CompanionCLI", dependencies: ["CompanionCore", "CompanionFeature"]),
        .executableTarget(name: "CompanionDemoApp", dependencies: ["CompanionCore", "CompanionFeature"]),
        .testTarget(name: "CompanionCoreTests", dependencies: ["CompanionCore", "CompanionFeature"])
    ]
)

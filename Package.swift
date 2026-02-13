// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-holons",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Holons",
            targets: ["Holons"]
        )
    ],
    targets: [
        .target(
            name: "Holons"
        ),
        .testTarget(
            name: "HolonsTests",
            dependencies: ["Holons"]
        )
    ]
)

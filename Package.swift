// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FlightBar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "FlightBar",
            path: "Sources/FlightBar"
        )
    ]
)

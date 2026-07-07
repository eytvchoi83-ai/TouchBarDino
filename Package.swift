// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TouchBarDino",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TouchBarDino", path: "Sources",
            linkerSettings: [.linkedFramework("IOKit")]
        )
    ]
)

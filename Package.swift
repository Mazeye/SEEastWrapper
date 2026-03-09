// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SEEastWrapper",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(
            name: "SEEastWrapper",
            targets: ["SEEastWrapper"]
        ),
        .executable(
            name: "SEEastWrapperDebugCLI",
            targets: ["SEEastWrapperDebugCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Mazeye/SwissEphemeris.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "SEEastWrapper",
            dependencies: ["SwissEphemeris"],
            path: "Sources/ChineseStarCatalog",
            exclude: []
        ),
        .executableTarget(
            name: "SEEastWrapperDebugCLI",
            dependencies: ["SEEastWrapper", "SwissEphemeris"],
            path: "Sources/SEEastWrapperDebugCLI"
        ),
        .testTarget(
            name: "StarPositionProviderTests",
            dependencies: ["SEEastWrapper", "SwissEphemeris"],
            path: "Tests/StarPositionProviderTests"
        ),
    ]
)

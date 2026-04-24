// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MacCCP",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacCCP", targets: ["MacCCP"])
    ],
    targets: [
        .systemLibrary(
            name: "CMpv",
            pkgConfig: "mpv",
            providers: [
                .brew(["mpv"])
            ]
        ),
        .executableTarget(
            name: "MacCCP",
            dependencies: ["CMpv"],
            path: "Sources/MacCCP"
        ),
        .testTarget(
            name: "MacCCPTests",
            dependencies: ["MacCCP"],
            path: "Tests/MacCCPTests"
        )
    ]
)

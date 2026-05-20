// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ZettairKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "ZettairKit", targets: ["ZettairKit"])],
    targets: [
        .target(name: "ZettairKit", path: "Sources/ZettairKit"),
        .testTarget(
            name: "ZettairKitTests",
            dependencies: ["ZettairKit"],
            path: "Tests/ZettairKitTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)

// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "MemfaultCloud",
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "MemfaultCloud", targets: ["MemfaultCloud"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "MemfaultCloud", dependencies: [], path: "MemfaultCloud/Classes")
    ]
)

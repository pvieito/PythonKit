// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "PythonKit",
    products: [
        .executable(
            name: "PythonTool",
            targets: ["PythonTool"]
        ),
        .library(
            name: "PythonLambdaSupport", // provides C-based interface to Python
            targets: ["PythonLambdaSupport"]),
        .library(
            name: "PythonKit",
            targets: ["PythonKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pvieito/LoggerKit.git", .branch("master")),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.0.1")),
    ],
    targets: [
        .target(
            name: "PythonTool",
            dependencies: ["LoggerKit", "PythonKit", .product(name: "ArgumentParser", package: "swift-argument-parser")],
            path: "PythonTool"
        ),
        .target(
            name: "libpylamsupport",
            dependencies: []
        ),
        .target(
            name: "PythonLambdaSupport",
            dependencies: ["libpylamsupport"]
        ),
        .target(
            name: "PythonKit",
            dependencies:[  "PythonLambdaSupport" ],
            path: "PythonKit"
        ),
        .testTarget(
            name: "PythonKitTests",
            dependencies: ["PythonKit"]
        ),
    ]
)

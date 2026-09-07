// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "PythonKit",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "PythonKit",
            targets: ["PythonKit"]
        )
    ],
    targets: [
        .target(
            name: "PythonKit",
            path: "PythonKit"
        ),
        .testTarget(
            name: "PythonKitTests",
            dependencies: [
                "PythonKit",
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)

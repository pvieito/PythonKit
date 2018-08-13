// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "PythonTool",
    products: [
        .executable(name: "PythonTool", targets: ["PythonTool"]),
        .library(name: "PythonKit", targets: ["PythonKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pvieito/CommandLineKit.git", .branch("master")),
        .package(url: "https://github.com/pvieito/LoggerKit.git", .branch("master")),
    ],
    targets: [
        .target(name: "PythonTool", dependencies: ["LoggerKit", "CommandLineKit", "PythonKit"], path: "PythonTool"),
        .target(name: "PythonKit", dependencies: ["Python3"], path: "PythonKit"),
        //.systemLibrary(name: "Python", path: "Python", pkgConfig: "python2"),
        .systemLibrary(name: "Python3", path: "Python3", pkgConfig: "python3"),
    ]
)

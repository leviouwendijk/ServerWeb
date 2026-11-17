// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ServerWeb",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ServerWeb",
            targets: ["ServerWeb"]
        ),
        .executable(
            name: "webserve",
            targets: ["ServerWebCLI"]
        ),
        .executable(
            name: "t_serverweb",
            targets: ["ServerWebTests"]
        ),
        .executable(
            name: "t_serverweb_demo",
            targets: ["ServerWebDemo"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/HTTP.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Server.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Constructors.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/HTML.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/CSS.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/JS.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Primitives.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Path.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Loggers.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Testing.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "ServerWeb",
            dependencies: [
                .product(name: "HTTP", package: "HTTP"),
                .product(name: "Server", package: "Server"),
                .product(name: "Constructors", package: "Constructors"),
                .product(name: "Path", package: "Path"),
                .product(name: "Loggers", package: "Loggers"),
            ]
        ),
        .executableTarget(
            name: "ServerWebCLI",
            dependencies: [
                "ServerWeb",
            ]
        ),
        .executableTarget(
            name: "ServerWebTests",
            dependencies: [
                "ServerWeb",
                .product(name: "HTTP", package: "HTTP"),
                .product(name: "Server", package: "Server"),
                .product(name: "Constructors", package: "Constructors"),
                .product(name: "Path", package: "Path"),
                .product(name: "Testing", package: "Testing"),
            ],
            path: "Testing/ServerWebTests"
        ),
        .executableTarget(
            name: "ServerWebDemo",
            dependencies: [
                "ServerWeb",
                .product(name: "HTTP", package: "HTTP"),
                .product(name: "Server", package: "Server"),
                .product(name: "Constructors", package: "Constructors"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "JS", package: "JS"),
                .product(name: "Path", package: "Path"),
                .product(name: "Primitives", package: "Primitives"),
            ],
            path: "Testing/ServerWebDemo"
        ),
    ]
)

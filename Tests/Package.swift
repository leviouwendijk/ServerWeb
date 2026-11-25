// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ServerWebTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
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
        .package(url: "https://github.com/swift-dsl/HTML.git", branch: "master"),
        .package(url: "https://github.com/swift-dsl/CSS.git", branch: "master"),
        .package(url: "https://github.com/swift-dsl/JS.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Primitives.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Path.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Testing.git", branch: "master"),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "ServerWebTests",
            dependencies: [
                .product(name: "ServerWeb", package: "ServerWeb"),
                .product(name: "HTTP", package: "HTTP"),
                .product(name: "Server", package: "Server"),
                .product(name: "Constructors", package: "Constructors"),
                .product(name: "Path", package: "Path"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
        .executableTarget(
            name: "ServerWebDemo",
            dependencies: [
                .product(name: "ServerWeb", package: "ServerWeb"),
                .product(name: "HTTP", package: "HTTP"),
                .product(name: "Server", package: "Server"),
                .product(name: "Constructors", package: "Constructors"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "JS", package: "JS"),
                .product(name: "Path", package: "Path"),
                .product(name: "Primitives", package: "Primitives"),
            ]
        ),
    ]
)

import Foundation
import Constructors
import Path
import ServerWeb
import Testing

enum ServerWebSiteTestSuite {
    static var testSuite: TestSuite {
        TestSuite(
            "serverweb.site",
            title: "ServerWeb site tests"
        ) {
            Test(
                "content types resolve from the path extension"
            ) {
                try Expect.equal(
                    WebContentType.forPath("/index.html"),
                    "text/html; charset=utf-8",
                    "serverweb.content-type.html"
                )

                try Expect.equal(
                    WebContentType.forPath("/assets/STYLE.CSS"),
                    "text/css; charset=utf-8",
                    "serverweb.content-type.case-insensitive"
                )

                try Expect.equal(
                    WebContentType.forPath("/app.js"),
                    "text/javascript; charset=utf-8",
                    "serverweb.content-type.js"
                )

                try Expect.equal(
                    WebContentType.forPath("/logo.png"),
                    "image/png",
                    "serverweb.content-type.png"
                )

                try Expect.equal(
                    WebContentType.forPath("/fonts/inter.woff2"),
                    "font/woff2",
                    "serverweb.content-type.woff2"
                )

                try Expect.equal(
                    WebContentType.forPath("/blob.unknownext"),
                    "application/octet-stream",
                    "serverweb.content-type.fallback"
                )
            }

            Test(
                "asset paths normalize to a single leading slash"
            ) {
                try Expect.equal(
                    WebAsset.normalized("about//index.html/"),
                    "/about/index.html",
                    "serverweb.asset.normalized"
                )

                try Expect.equal(
                    WebAsset.normalized(""),
                    "/",
                    "serverweb.asset.normalized-root"
                )
            }

            Test(
                "page injects stylesheet and script references"
            ) {
                let site = WebSite.page(
                    html: "<html><head><title>t</title></head><body><p>hi</p></body></html>",
                    css: "body { color: red; }",
                    js: "console.log(1);"
                )

                try Expect.equal(
                    site.assets.map(\.path),
                    [
                        "/index.html",
                        "/style.css",
                        "/app.js",
                    ],
                    "serverweb.page.paths"
                )

                let html = try Expect.notNil(
                    site.asset(at: "/index.html")?.contents,
                    "serverweb.page.index"
                )

                try Expect.contains(
                    html,
                    "<link rel=\"stylesheet\" href=\"/style.css\"></head>",
                    "serverweb.page.stylesheet-before-head-close"
                )

                try Expect.contains(
                    html,
                    "<script src=\"/app.js\"></script></body>",
                    "serverweb.page.script-before-body-close"
                )
            }

            Test(
                "page leaves existing references alone"
            ) {
                let html = "<head><link rel=\"stylesheet\" href=\"/style.css\"></head><body></body>"
                let site = WebSite.page(
                    html: html,
                    css: "p {}"
                )

                try Expect.equal(
                    site.asset(at: "/index.html")?.contents,
                    html,
                    "serverweb.page.no-duplicate-reference"
                )
            }

            Test(
                "constructors artifacts map to request paths"
            ) {
                let site = WebSite(
                    artifacts: [
                        StaticTextArtifact(
                            output: StandardPath(rawPath: "index.html"),
                            contents: "<p>home</p>"
                        ),
                        StaticTextArtifact(
                            output: StandardPath(rawPath: "about/index.html"),
                            contents: "<p>about</p>"
                        ),
                        StaticTextArtifact(
                            output: StandardPath(rawPath: "assets/site.css"),
                            contents: "p {}"
                        ),
                    ]
                )

                try Expect.equal(
                    site.assets.map(\.path),
                    [
                        "/index.html",
                        "/about/index.html",
                        "/assets/site.css",
                    ],
                    "serverweb.constructors.paths"
                )

                try Expect.equal(
                    site.asset(at: "/assets/site.css")?.contentType,
                    "text/css; charset=utf-8",
                    "serverweb.constructors.content-type"
                )

                try Expect.equal(
                    site.servedPaths.map(\.path),
                    [
                        "/index.html",
                        "/about/index.html",
                        "/assets/site.css",
                        "/",
                        "/about/",
                        "/about",
                    ],
                    "serverweb.constructors.served-paths"
                )

                try Expect.equal(
                    site.servedPaths.first { $0.path == "/about/" }?.asset.contents,
                    "<p>about</p>",
                    "serverweb.constructors.directory-index"
                )
            }

            Test(
                "directory load keeps text and binary files byte-exact"
            ) {
                let root = FileManager.default.temporaryDirectory
                    .appendingPathComponent("serverweb-\(UUID().uuidString)")

                defer {
                    try? FileManager.default.removeItem(at: root)
                }

                try FileManager.default.createDirectory(
                    at: root.appendingPathComponent("css"),
                    withIntermediateDirectories: true
                )

                try "<p>dir</p>".write(
                    to: root.appendingPathComponent("index.html"),
                    atomically: true,
                    encoding: .utf8
                )

                try "p {}".write(
                    to: root.appendingPathComponent("css/site.css"),
                    atomically: true,
                    encoding: .utf8
                )

                try Data([0x89, 0x50, 0x4E, 0x47]).write(
                    to: root.appendingPathComponent("logo.png")
                )

                let load = try WebSite.directory(
                    at: root
                )

                try Expect.equal(
                    load.site.assets.map(\.path),
                    [
                        "/css/site.css",
                        "/index.html",
                        "/logo.png",
                    ],
                    "serverweb.directory.paths"
                )

                try Expect.equal(
                    load.site.asset(at: "/logo.png")?.data,
                    Data([0x89, 0x50, 0x4E, 0x47]),
                    "serverweb.directory.binary-bytes"
                )

                try Expect.equal(
                    load.site.asset(at: "/logo.png")?.contentType,
                    "image/png",
                    "serverweb.directory.binary-content-type"
                )

                try Expect.isEmpty(
                    load.skipped,
                    "serverweb.directory.nothing-skipped"
                )
            }
        }
    }
}

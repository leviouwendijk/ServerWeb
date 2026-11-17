import Foundation
import ServerWeb
import Testing

/// Byte-level fetches; `HTTPClient` still decodes bodies as text.
enum ServerWebFetch {
    static let session = URLSession(configuration: .ephemeral)

    static func get(
        _ path: String,
        from base: URL
    ) async throws -> (data: Data, response: HTTPURLResponse) {
        let url = try Expect.notNil(
            URL(string: path, relativeTo: base),
            "serverweb.fetch.url"
        )

        let (data, response) = try await session.data(from: url)

        let http = try Expect.notNil(
            response as? HTTPURLResponse,
            "serverweb.fetch.http-response"
        )

        return (data, http)
    }

    static func text(
        _ path: String,
        from base: URL
    ) async throws -> String {
        String(
            decoding: try await get(path, from: base).data,
            as: UTF8.self
        )
    }
}

enum ServerWebLiveTestSuite {
    static let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0xFF, 0xFE, 0x80])

    static var testSuite: TestSuite {
        TestSuite(
            "serverweb.live",
            title: "ServerWeb binary and live reload tests"
        ) {
            Test(
                "binary assets are served byte-exact with their content type"
            ) {
                let server = WebServer(
                    site: WebSite(
                        assets: [
                            WebAsset(path: "/index.html", contents: "<p>x</p>"),
                            WebAsset(path: "/img/logo.png", data: png),
                        ]
                    ),
                    logLevel: .error
                )

                let base = try await server.start()

                defer {
                    Task { await server.stop() }
                }

                let (data, response) = try await ServerWebFetch.get("/img/logo.png", from: base)

                try Expect.equal(
                    response.statusCode,
                    200,
                    "serverweb.binary.status"
                )

                try Expect.equal(
                    data,
                    png,
                    "serverweb.binary.bytes"
                )

                try Expect.equal(
                    response.value(forHTTPHeaderField: "Content-Type"),
                    "image/png",
                    "serverweb.binary.content-type"
                )

                try Expect.equal(
                    response.value(forHTTPHeaderField: "Content-Length"),
                    "\(png.count)",
                    "serverweb.binary.content-length"
                )
            }

            Test(
                "live reload injects the current token and the endpoint reports it"
            ) {
                let server = WebServer(
                    site: WebSite.page(
                        html: "<html><body><h1>live</h1></body></html>"
                    ),
                    liveReload: true,
                    logLevel: .error
                )

                let base = try await server.start()

                defer {
                    Task { await server.stop() }
                }

                let html = try await ServerWebFetch.text("/", from: base)
                let token = try await ServerWebFetch.text(WebLiveReload.endpoint, from: base)

                try Expect.equal(
                    token,
                    server.store.token,
                    "serverweb.live.endpoint-token"
                )

                try Expect.contains(
                    html,
                    WebLiveReload.marker,
                    "serverweb.live.script-injected"
                )

                try Expect.contains(
                    html,
                    "const served = \"\(token)\";",
                    "serverweb.live.script-carries-token"
                )

                try Expect.contains(
                    html,
                    "</script>\n</body>",
                    "serverweb.live.script-before-body-close"
                )
            }

            Test(
                "replace swaps assets, adds new paths and changes the token"
            ) {
                let server = WebServer(
                    site: WebSite.page(html: "<p>one</p>"),
                    liveReload: true,
                    logLevel: .error
                )

                let base = try await server.start()

                defer {
                    Task { await server.stop() }
                }

                let before = try await ServerWebFetch.text(WebLiveReload.endpoint, from: base)

                server.replace(
                    WebSite(
                        assets: [
                            WebAsset(path: "/index.html", contents: "<p>two</p>"),
                            WebAsset(path: "/added.css", contents: "p {}"),
                        ]
                    )
                )

                let after = try await ServerWebFetch.text(WebLiveReload.endpoint, from: base)
                let index = try await ServerWebFetch.text("/", from: base)
                let added = try await ServerWebFetch.get("/added.css", from: base)

                try Expect.notEqual(
                    before,
                    after,
                    "serverweb.replace.token-changes"
                )

                try Expect.contains(
                    index,
                    "<p>two</p>",
                    "serverweb.replace.new-content"
                )

                try Expect.equal(
                    added.response.statusCode,
                    200,
                    "serverweb.replace.new-path"
                )
            }

            Test(
                "without live reload html is served untouched and the endpoint is absent"
            ) {
                let server = WebServer(
                    site: WebSite.page(html: "<html><body></body></html>"),
                    logLevel: .error
                )

                let base = try await server.start()

                defer {
                    Task { await server.stop() }
                }

                let html = try await ServerWebFetch.text("/", from: base)
                let endpoint = try await ServerWebFetch.get(WebLiveReload.endpoint, from: base)

                try Expect.equal(
                    html,
                    "<html><body></body></html>",
                    "serverweb.static.untouched"
                )

                try Expect.equal(
                    endpoint.response.statusCode,
                    404,
                    "serverweb.static.no-endpoint"
                )
            }

            Test(
                "directory watcher reports added and modified files"
            ) {
                let root = FileManager.default.temporaryDirectory
                    .appendingPathComponent("serverweb-watch-\(UUID().uuidString)")

                try FileManager.default.createDirectory(
                    at: root,
                    withIntermediateDirectories: true
                )

                defer {
                    try? FileManager.default.removeItem(at: root)
                }

                try "<p>a</p>".write(
                    to: root.appendingPathComponent("index.html"),
                    atomically: true,
                    encoding: .utf8
                )

                let changes = ChangeCounter()
                let watcher = WebDirectoryWatcher(
                    root: root,
                    interval: .milliseconds(50)
                )

                watcher.start {
                    changes.increment()
                }

                defer {
                    watcher.stop()
                }

                try await Task.sleep(for: .milliseconds(150))

                try "p {}".write(
                    to: root.appendingPathComponent("added.css"),
                    atomically: true,
                    encoding: .utf8
                )

                try await changes.wait(atLeast: 1)

                try "<p>a much longer body</p>".write(
                    to: root.appendingPathComponent("index.html"),
                    atomically: true,
                    encoding: .utf8
                )

                try await changes.wait(atLeast: 2)
            }
        }
    }
}

final class ChangeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() {
        lock.withLock { count += 1 }
    }

    var value: Int {
        lock.withLock { count }
    }

    func wait(
        atLeast expected: Int,
        timeout: Duration = .seconds(3)
    ) async throws {
        let deadline = ContinuousClock.now + timeout

        while value < expected, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(25))
        }

        try Expect.greaterThanOrEqual(
            value,
            expected
        )
    }
}

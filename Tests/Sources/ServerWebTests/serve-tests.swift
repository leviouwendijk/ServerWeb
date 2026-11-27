import Foundation
import HTTP
import Server
import ServerWeb
import Testing

final class RecordingBrowser: BrowserOpening, @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [URL] = []

    var opened: [URL] {
        lock.withLock { urls }
    }

    func open(_ url: URL) throws {
        lock.withLock {
            urls.append(url)
        }
    }
}

enum ServerWebServeTestSuite {
    static let site = WebSite.page(
        html: "<html><head></head><body><h1>served</h1></body></html>",
        css: "h1 { color: teal; }",
        js: "document.title = 'served';"
    )

    static var testSuite: TestSuite {
        TestSuite(
            "serverweb.serve",
            title: "ServerWeb serve tests"
        ) {
            Test(
                "host table picks the site by Host, ignoring port and case, with aliases"
            ) {
                let table = WebHostTable()
                table.serve(site, host: "Example.com", aliases: ["www.example.com"])

                try Expect.notNil(table.store(forHost: "example.com:8080"), "serverweb.hosts.port-ignored")
                try Expect.notNil(table.store(forHost: "WWW.example.com"), "serverweb.hosts.alias")
                try Expect.true(table.store(forHost: "other.example") == nil, "serverweb.hosts.unknown")
                try Expect.notNil(
                    table.store(forHost: "example.com")?.asset(forRequestPath: "/style.css"),
                    "serverweb.hosts.asset"
                )
            }

            Test(
                "serves assets with content types and 404s unknown paths"
            ) {
                let server = WebServer(
                    site: site,
                    logLevel: .error
                )

                let url = try await server.start()

                defer {
                    Task {
                        await server.stop()
                    }
                }

                let port = try Expect.notNil(
                    url.port,
                    "serverweb.serve.bound-port"
                )

                try Expect.notEqual(
                    port,
                    0,
                    "serverweb.serve.bound-port-resolved"
                )

                let client = HTTPClient(
                    config: HTTPClientConfig(
                        host: server.config.host,
                        port: UInt16(port)
                    )
                )

                let root = try await client.get("/")

                try Expect.equal(
                    root.status,
                    .ok,
                    "serverweb.serve.root-status"
                )

                try Expect.contains(
                    root.body,
                    "<h1>served</h1>",
                    "serverweb.serve.root-body"
                )

                try Expect.equal(
                    root.headers.contentType,
                    "text/html; charset=utf-8",
                    "serverweb.serve.root-content-type"
                )

                let css = try await client.get("/style.css")

                try Expect.equal(
                    css.headers.contentType,
                    "text/css; charset=utf-8",
                    "serverweb.serve.css-content-type"
                )

                try Expect.equal(
                    css.body,
                    "h1 { color: teal; }",
                    "serverweb.serve.css-body"
                )

                let js = try await client.get("/app.js")

                try Expect.equal(
                    js.headers.contentType,
                    "text/javascript; charset=utf-8",
                    "serverweb.serve.js-content-type"
                )

                let missing = try await client.get("/missing.html")

                try Expect.equal(
                    missing.status,
                    .notFound,
                    "serverweb.serve.missing-status"
                )
            }

            Test(
                "startAndOpen hands the bound url to the browser"
            ) {
                let browser = RecordingBrowser()
                let server = WebServer(
                    site: site,
                    logLevel: .error
                )

                let url = try await server.startAndOpen(
                    using: browser
                )

                let port = try Expect.notNil(
                    await server.boundPort(),
                    "serverweb.serve.open-bound-port"
                )

                await server.stop()

                try Expect.equal(
                    browser.opened,
                    [
                        url,
                    ],
                    "serverweb.serve.opened-url"
                )

                try Expect.equal(
                    url.absoluteString,
                    "http://127.0.0.1:\(port)/",
                    "serverweb.serve.url-shape"
                )
            }
        }
    }
}

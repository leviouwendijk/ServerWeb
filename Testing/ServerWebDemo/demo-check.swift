import Foundation
import HTTP
import Server
import ServerWeb

/// Fetches every asset back over the wire and compares it with the site.
enum DemoCheck {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    static func run(
        site: WebSite,
        url: URL
    ) async throws -> [String] {
        guard let host = url.host,
              let port = url.port else {
            throw Failure(description: "Served URL has no host/port: \(url)")
        }

        let client = HTTPClient(
            config: HTTPClientConfig(
                host: host,
                port: UInt16(port)
            )
        )

        var lines: [String] = []
        var failures: [String] = []

        if site.asset(at: site.index) == nil {
            failures.append("/: site has no index asset \(site.index)")
        }

        for (path, expected) in site.servedPaths {
            let response = try await client.get(path)

            if response.status != .ok {
                failures.append("\(path): status \(response.status.code)")
            } else if response.headers.contentType != expected.contentType {
                failures.append("\(path): content-type \(response.headers.contentType ?? "nil") != \(expected.contentType)")
            } else if response.body != expected.contents {
                failures.append("\(path): body differs (\(response.body.utf8.count) vs \(expected.contents.utf8.count) bytes)")
            } else {
                lines.append("ok    \(path)  \(expected.contentType)  \(expected.contents.utf8.count)B")
            }
        }

        let missing = try await client.get("/__missing__")

        if missing.status == .notFound {
            lines.append("ok    /__missing__  404")
        } else {
            failures.append("/__missing__: expected 404, got \(missing.status.code)")
        }

        guard failures.isEmpty else {
            throw Failure(
                description: (lines + failures.map { "FAIL  \($0)" }).joined(separator: "\n")
            )
        }

        return lines
    }
}

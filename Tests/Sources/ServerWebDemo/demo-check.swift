import Foundation
import ServerWeb

/// Fetches every served path back over the wire and compares bytes with the site.
///
/// Uses URLSession rather than `HTTPClient`, which still decodes bodies as text.
enum DemoCheck {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    static func run(
        site: WebSite,
        url base: URL,
        liveReload: Bool
    ) async throws -> [String] {
        let session = URLSession(configuration: .ephemeral)

        var lines: [String] = []
        var failures: [String] = []

        if site.asset(at: site.index) == nil {
            failures.append("/: site has no index asset \(site.index)")
        }

        for (path, expected) in site.servedPaths {
            let (data, response) = try await fetch(path, base: base, session: session)
            let contentType = response.value(forHTTPHeaderField: "Content-Type")
            let injected = liveReload && WebContentType.isHTML(expected.contentType)

            if response.statusCode != 200 {
                failures.append("\(path): status \(response.statusCode)")
            } else if contentType != expected.contentType {
                failures.append("\(path): content-type \(contentType ?? "nil") != \(expected.contentType)")
            } else if injected {
                let body = String(decoding: data, as: UTF8.self)

                if body.contains(WebLiveReload.marker) {
                    lines.append("ok    \(path)  \(expected.contentType)  \(data.count)B  +live-reload")
                } else {
                    failures.append("\(path): live-reload script missing")
                }
            } else if data != expected.data {
                failures.append("\(path): bytes differ (\(data.count) vs \(expected.data.count))")
            } else {
                lines.append("ok    \(path)  \(expected.contentType)  \(data.count)B")
            }
        }

        let (_, missing) = try await fetch("/__missing__", base: base, session: session)

        if missing.statusCode == 404 {
            lines.append("ok    /__missing__  404")
        } else {
            failures.append("/__missing__: expected 404, got \(missing.statusCode)")
        }

        if liveReload {
            let (token, response) = try await fetch(WebLiveReload.endpoint, base: base, session: session)

            if response.statusCode == 200, !token.isEmpty {
                lines.append("ok    \(WebLiveReload.endpoint)  token \(String(decoding: token, as: UTF8.self))")
            } else {
                failures.append("\(WebLiveReload.endpoint): status \(response.statusCode)")
            }
        }

        guard failures.isEmpty else {
            throw Failure(
                description: (lines + failures.map { "FAIL  \($0)" }).joined(separator: "\n")
            )
        }

        return lines
    }

    private static func fetch(
        _ path: String,
        base: URL,
        session: URLSession
    ) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: path, relativeTo: base) else {
            throw Failure(description: "Bad path \(path)")
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw Failure(description: "\(path): not an HTTP response")
        }

        return (data, http)
    }
}

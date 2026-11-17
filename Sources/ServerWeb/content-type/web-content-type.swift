import Foundation

public enum WebContentType {
    public static let fallback = "text/plain; charset=utf-8"

    public static let byExtension: [String: String] = [
        "html": "text/html; charset=utf-8",
        "htm": "text/html; charset=utf-8",
        "css": "text/css; charset=utf-8",
        "js": "text/javascript; charset=utf-8",
        "mjs": "text/javascript; charset=utf-8",
        "json": "application/json; charset=utf-8",
        "map": "application/json; charset=utf-8",
        "svg": "image/svg+xml; charset=utf-8",
        "txt": "text/plain; charset=utf-8",
        "md": "text/markdown; charset=utf-8",
        "xml": "application/xml; charset=utf-8",
        "webmanifest": "application/manifest+json; charset=utf-8",
    ]

    /// Resolves a content type from the last path extension.
    ///
    /// Only textual types are listed: `HTTPResponse.body` is a `String`,
    /// so binary assets cannot be served yet.
    public static func forPath(
        _ path: String
    ) -> String {
        let ext = (path as NSString)
            .pathExtension
            .lowercased()

        return byExtension[ext] ?? fallback
    }

    public static func isServable(
        _ path: String
    ) -> Bool {
        let ext = (path as NSString)
            .pathExtension
            .lowercased()

        return byExtension[ext] != nil
    }
}

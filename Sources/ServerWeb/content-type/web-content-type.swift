import Foundation

public enum WebContentType {
    public static let fallback = "application/octet-stream"

    public static let byExtension: [String: String] = [
        // text
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
        "csv": "text/csv; charset=utf-8",
        "xml": "application/xml; charset=utf-8",
        "webmanifest": "application/manifest+json; charset=utf-8",

        // images
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "webp": "image/webp",
        "avif": "image/avif",
        "ico": "image/x-icon",

        // fonts
        "woff": "font/woff",
        "woff2": "font/woff2",
        "ttf": "font/ttf",
        "otf": "font/otf",

        // media / other
        "pdf": "application/pdf",
        "mp3": "audio/mpeg",
        "wav": "audio/wav",
        "mp4": "video/mp4",
        "webm": "video/webm",
        "wasm": "application/wasm",
        "zip": "application/zip",
    ]

    /// Resolves a content type from the last path extension.
    public static func forPath(
        _ path: String
    ) -> String {
        let ext = (path as NSString)
            .pathExtension
            .lowercased()

        return byExtension[ext] ?? fallback
    }

    public static func isHTML(
        _ contentType: String
    ) -> Bool {
        contentType.lowercased().hasPrefix("text/html")
    }
}

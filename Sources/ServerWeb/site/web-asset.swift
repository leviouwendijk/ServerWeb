import Foundation

public struct WebAsset: Sendable, Equatable {
    /// Absolute request path, always starting with `/`.
    public let path: String
    public let data: Data
    public let contentType: String

    /// UTF-8 view of `data`, for textual assets.
    public var contents: String {
        String(
            decoding: data,
            as: UTF8.self
        )
    }

    public init(
        path: String,
        data: Data,
        contentType: String? = nil
    ) {
        let normalized = Self.normalized(
            path
        )

        self.path = normalized
        self.data = data
        self.contentType = contentType ?? WebContentType.forPath(
            normalized
        )
    }

    public init(
        path: String,
        contents: String,
        contentType: String? = nil
    ) {
        self.init(
            path: path,
            data: Data(contents.utf8),
            contentType: contentType
        )
    }

    public static func normalized(
        _ path: String
    ) -> String {
        let trimmed = path
            .split(separator: "/", omittingEmptySubsequences: true)
            .joined(separator: "/")

        return "/" + trimmed
    }
}

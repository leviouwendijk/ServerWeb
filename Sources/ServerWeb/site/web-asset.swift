import Foundation

public struct WebAsset: Sendable, Equatable {
    /// Absolute request path, always starting with `/`.
    public let path: String
    public let contents: String
    public let contentType: String

    public init(
        path: String,
        contents: String,
        contentType: String? = nil
    ) {
        let normalized = Self.normalized(
            path
        )

        self.path = normalized
        self.contents = contents
        self.contentType = contentType ?? WebContentType.forPath(
            normalized
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

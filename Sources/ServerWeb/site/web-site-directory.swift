import Foundation

public enum WebSiteDirectoryError: Error, LocalizedError {
    case notADirectory(path: String)

    public var errorDescription: String? {
        switch self {
        case .notADirectory(let path):
            return "Not a directory: \(path)"
        }
    }
}

public struct WebSiteDirectoryLoad: Sendable {
    public let site: WebSite

    /// Files left out because they are not textual (see `WebContentType`).
    public let skipped: [String]
}

public extension WebSite {
    static func directory(
        at root: URL,
        index: String = "/index.html"
    ) throws -> WebSiteDirectoryLoad {
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(
            atPath: root.path,
            isDirectory: &isDirectory
        ), isDirectory.boolValue else {
            throw WebSiteDirectoryError.notADirectory(
                path: root.path
            )
        }

        let base = root.standardizedFileURL.path

        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var assets: [WebAsset] = []
        var skipped: [String] = []

        while let url = enumerator?.nextObject() as? URL {
            let values = try url.resourceValues(
                forKeys: [.isRegularFileKey]
            )

            guard values.isRegularFile == true else {
                continue
            }

            let full = url.standardizedFileURL.path
            let relative = String(
                full.dropFirst(base.count)
            )

            guard WebContentType.isServable(relative),
                  let contents = try? String(contentsOf: url, encoding: .utf8)
            else {
                skipped.append(
                    relative
                )
                continue
            }

            assets.append(
                WebAsset(
                    path: relative,
                    contents: contents
                )
            )
        }

        return WebSiteDirectoryLoad(
            site: WebSite(
                assets: assets.sorted { $0.path < $1.path },
                index: index
            ),
            skipped: skipped.sorted()
        )
    }
}

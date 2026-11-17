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

    /// Files that could not be read.
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

        var assets: [WebAsset] = []
        var skipped: [String] = []

        for file in try WebDirectoryFiles.list(root) {
            guard let data = try? Data(contentsOf: file.url) else {
                skipped.append(
                    file.relativePath
                )
                continue
            }

            assets.append(
                WebAsset(
                    path: file.relativePath,
                    data: data
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

/// Regular, non-hidden files below a root, with their `/`-prefixed relative paths.
enum WebDirectoryFiles {
    struct File {
        let url: URL
        let relativePath: String
        let modified: Date
        let size: Int
    }

    static func list(
        _ root: URL
    ) throws -> [File] {
        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .contentModificationDateKey,
            .fileSizeKey,
        ]

        let base = root.standardizedFileURL.resolvingSymlinksInPath().path

        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        )

        var files: [File] = []

        while let url = enumerator?.nextObject() as? URL {
            let values = try url.resourceValues(
                forKeys: Set(keys)
            )

            guard values.isRegularFile == true else {
                continue
            }

            let full = url.standardizedFileURL.resolvingSymlinksInPath().path

            files.append(
                File(
                    url: url,
                    relativePath: String(full.dropFirst(base.count)),
                    modified: values.contentModificationDate ?? .distantPast,
                    size: values.fileSize ?? 0
                )
            )
        }

        return files
    }
}

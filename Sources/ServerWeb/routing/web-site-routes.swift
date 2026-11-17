import Foundation
import HTTP
import Server

public extension WebAsset {
    var response: HTTPResponse {
        HTTPResponse(
            status: .ok,
            headers: [
                "Content-Type": contentType,
                "Cache-Control": "no-store",
            ],
            body: contents
        )
    }
}

public extension WebSite {
    static let directoryIndexName = "index.html"

    /// Every request path the site answers, mapped to the asset it serves.
    ///
    /// Besides each asset's own path, `/` serves the index asset and every
    /// `<dir>/index.html` is also served at `<dir>/` and `<dir>`, because the
    /// router matches paths exactly.
    var servedPaths: [(path: String, asset: WebAsset)] {
        var served: [(path: String, asset: WebAsset)] = []
        var seen: Set<String> = []

        func add(_ path: String, _ asset: WebAsset) {
            guard seen.insert(path).inserted else {
                return
            }
            served.append((path, asset))
        }

        for asset in assets {
            add(asset.path, asset)
        }

        if let index = asset(at: index) {
            add("/", index)
        }

        for asset in assets where (asset.path as NSString).lastPathComponent == Self.directoryIndexName {
            let directory = String(
                asset.path.dropLast(Self.directoryIndexName.count)
            )

            guard directory != "/" else {
                continue
            }

            add(directory, asset)
            add(String(directory.dropLast()), asset)
        }

        return served
    }

    /// One GET route per served path. Unmatched paths fall through to the router's 404.
    var routes: [Route] {
        servedPaths.map { path, asset in
            Route(
                method: .get,
                path: path
            ) { _, _ in
                asset.response
            }
        }
    }
}

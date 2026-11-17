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
    /// One GET route per asset, plus `/` for the index asset.
    /// Unmatched paths fall through to the router's 404.
    var routes: [Route] {
        var routes = assets.map { asset in
            Route(
                method: .get,
                path: asset.path
            ) { _, _ in
                asset.response
            }
        }

        if let index = asset(at: index),
           index.path != "/" {
            routes.append(
                Route(
                    method: .get,
                    path: "/"
                ) { _, _ in
                    index.response
                }
            )
        }

        return routes
    }
}

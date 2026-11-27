import Foundation
import HTTP

/// Several sites in one process, chosen by the request's `Host` header:
/// what the site service serves from memory. Each host's site is
/// replaceable while running, like `WebServer`'s.
public final class WebHostTable: @unchecked Sendable {
    private let lock = NSLock()
    private var stores: [String: WebSiteStore] = [:]
    private var aliases: [String: String] = [:]

    public init() {}

    /// Serves `site` for `host`, and for each alias (`www.<host>`).
    public func serve(
        _ site: WebSite,
        host: String,
        aliases: [String] = []
    ) {
        let host = Self.normalized(host)

        lock.withLock {
            if let store = stores[host] {
                store.replace(site)
            } else {
                stores[host] = WebSiteStore(site: site)
            }
            for alias in aliases {
                self.aliases[Self.normalized(alias)] = host
            }
        }
    }

    public var hosts: [String] {
        lock.withLock { stores.keys.sorted() }
    }

    public func store(
        forHost host: String
    ) -> WebSiteStore? {
        let host = Self.normalized(host)
        return lock.withLock {
            stores[host] ?? aliases[host].flatMap { stores[$0] }
        }
    }

    /// The response for `request`, or nil (unknown host, unknown path,
    /// not GET or HEAD): the caller's 404.
    public func response(
        for request: HTTPRequest
    ) -> HTTPResponse? {
        guard request.method == .get || request.method == .head,
              let host = request.header("Host"),
              let store = store(forHost: host),
              let asset = store.asset(forRequestPath: request.path.raw)
        else {
            return nil
        }

        var response = asset.response

        if request.method == .head {
            response.bodyData = Data()
        }

        return response
    }

    /// Lowercased, without a port.
    static func normalized(
        _ host: String
    ) -> String {
        let lowered = host.lowercased()
        guard let colon = lowered.lastIndex(of: ":"),
              !lowered.contains("]")
        else {
            return lowered
        }
        return String(lowered[..<colon])
    }
}

import Foundation

/// The site a running `WebServer` serves, replaceable while it runs.
///
/// Each replacement bumps `generation`; together with the per-process
/// `instance` it forms the live-reload `token`, so both a rebuilt site and a
/// restarted server make open pages reload.
public final class WebSiteStore: @unchecked Sendable {
    public let instance: String

    private let lock = NSLock()
    private var current: WebSite
    private var table: [String: WebAsset]
    private var currentGeneration = 0

    public init(
        site: WebSite
    ) {
        self.instance = String(
            UUID().uuidString.prefix(8)
        ).lowercased()
        self.current = site
        self.table = Self.table(for: site)
    }

    public var site: WebSite {
        lock.withLock { current }
    }

    public var generation: Int {
        lock.withLock { currentGeneration }
    }

    public var token: String {
        lock.withLock { "\(instance)-\(currentGeneration)" }
    }

    public func replace(
        _ site: WebSite
    ) {
        let table = Self.table(for: site)

        lock.withLock {
            current = site
            self.table = table
            currentGeneration += 1
        }
    }

    public func asset(
        forRequestPath path: String
    ) -> WebAsset? {
        lock.withLock { table[path] }
    }

    private static func table(
        for site: WebSite
    ) -> [String: WebAsset] {
        Dictionary(
            site.servedPaths.map { ($0.path, $0.asset) },
            uniquingKeysWith: { first, _ in first }
        )
    }
}

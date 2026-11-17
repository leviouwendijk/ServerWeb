import Foundation
import HTTP
import Server
import Loggers

public enum WebServerError: Error, LocalizedError {
    case missingBoundPort

    public var errorDescription: String? {
        switch self {
        case .missingBoundPort:
            return "Server started but reported no bound port"
        }
    }
}

public struct WebServer: Sendable {
    public let store: WebSiteStore
    public let liveReload: Bool
    public let process: ServerProcess

    public var site: WebSite {
        store.site
    }

    public var config: ServerConfig {
        process.config
    }

    /// - Parameters:
    ///   - port: `nil` (or `0`) lets the kernel pick a free port.
    ///   - liveReload: inject a polling script into HTML responses and serve
    ///     `WebLiveReload.endpoint`; pages reload on `replace(_:)` or restart.
    public init(
        site: WebSite,
        host: String = "127.0.0.1",
        port: UInt16? = nil,
        liveReload: Bool = false,
        logLevel: LogLevel = .info,
        logger: StandardLogger? = nil
    ) {
        let store = WebSiteStore(site: site)

        self.store = store
        self.liveReload = liveReload
        self.process = ServerProcess(
            config: ServerConfig(
                name: "serverweb",
                port: port ?? 0,
                host: host,
                logLevel: logLevel
            ),
            routes: liveReload ? [WebLiveReload.route(store: store)] : [],
            unmatched: { request in
                Self.respond(
                    to: request,
                    store: store,
                    liveReload: liveReload
                )
            },
            logger: logger
        )
    }

    /// Swaps the served site; with live reload on, open pages reload.
    public func replace(
        _ site: WebSite
    ) {
        store.replace(site)
    }

    /// Port the listener bound, once started.
    public func boundPort() async -> UInt16? {
        await process.engine.listenerBoundPort
    }

    /// URL of the running server, once started.
    public func url() async -> URL? {
        guard let port = await boundPort() else {
            return nil
        }

        return URL(string: "http://\(config.host):\(port)/")
    }

    /// Binds the port and returns the served URL once the listener is ready.
    @discardableResult
    public func start() async throws -> URL {
        try await process.engine.start()

        guard let url = await url() else {
            await stop()
            throw WebServerError.missingBoundPort
        }

        return url
    }

    public func stop() async {
        await process.engine.stop()
    }

    public func waitForTermination() async throws -> ServerEngine.Termination {
        try await process.engine.waitForTermination()
    }

    /// Starts the server, opens it in the browser and returns its URL.
    @discardableResult
    public func startAndOpen(
        using browser: BrowserOpening = SystemBrowser()
    ) async throws -> URL {
        let url = try await start()
        try browser.open(url)
        return url
    }

    static func respond(
        to request: HTTPRequest,
        store: WebSiteStore,
        liveReload: Bool
    ) -> HTTPResponse? {
        guard request.method == .get || request.method == .head,
              let asset = store.asset(forRequestPath: request.path.raw) else {
            return nil
        }

        var response = asset.response

        if liveReload, WebContentType.isHTML(asset.contentType) {
            response.body = WebLiveReload.inject(
                token: store.token,
                into: asset.contents
            )
        }

        if request.method == .head {
            response.bodyData = Data()
        }

        return response
    }
}

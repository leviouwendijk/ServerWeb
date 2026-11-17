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
    public let site: WebSite
    public let process: ServerProcess

    public var config: ServerConfig {
        process.config
    }

    /// - Parameter port: `nil` (or `0`) lets the kernel pick a free port.
    public init(
        site: WebSite,
        host: String = "127.0.0.1",
        port: UInt16? = nil,
        logLevel: LogLevel = .info,
        logger: StandardLogger? = nil
    ) {
        self.site = site
        self.process = ServerProcess(
            config: ServerConfig(
                name: "serverweb",
                port: port ?? 0,
                host: host,
                logLevel: logLevel
            ),
            routes: site.routes,
            logger: logger
        )
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
}

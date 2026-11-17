import Foundation
import HTTP
import Server
import Loggers

public struct WebServer: Sendable {
    public let site: WebSite
    public let process: ServerProcess

    public var config: ServerConfig {
        process.config
    }

    public var url: URL {
        URL(string: "http://\(config.host):\(config.port)/")!
    }

    /// - Parameter port: `nil` picks a free port.
    public init(
        site: WebSite,
        host: String = "127.0.0.1",
        port: UInt16? = nil,
        logLevel: LogLevel = .info,
        logger: StandardLogger? = nil
    ) throws {
        let resolved = try port ?? WebPort.available(
            host: host
        )

        self.site = site
        self.process = ServerProcess(
            config: ServerConfig(
                name: "serverweb",
                port: resolved,
                host: host,
                logLevel: logLevel
            ),
            routes: site.routes,
            logger: logger
        )
    }

    /// Binds the port and returns once the listener is ready.
    @discardableResult
    public func start() async throws -> URL {
        try await process.engine.start()
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

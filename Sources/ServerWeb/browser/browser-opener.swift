import Foundation

public protocol BrowserOpening: Sendable {
    func open(_ url: URL) throws
}

public enum BrowserOpenError: Error, LocalizedError {
    case failed(url: URL, status: Int32)

    public var errorDescription: String? {
        switch self {
        case .failed(let url, let status):
            return "Could not open \(url.absoluteString) (open exited with \(status))"
        }
    }
}

/// Opens URLs in the user's default browser via `/usr/bin/open`,
/// which keeps AppKit out of the library.
public struct SystemBrowser: BrowserOpening {
    public init() {}

    public func open(_ url: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url.absoluteString]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw BrowserOpenError.failed(
                url: url,
                status: process.terminationStatus
            )
        }
    }
}

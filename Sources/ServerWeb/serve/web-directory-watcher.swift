import Foundation

/// Polls a directory tree and calls back when any file is added, removed or changed
/// (by path, modification date and size).
public final class WebDirectoryWatcher: @unchecked Sendable {
    public let root: URL
    public let interval: Duration

    private let lock = NSLock()
    private var task: Task<Void, Never>?

    public init(
        root: URL,
        interval: Duration = .milliseconds(300)
    ) {
        self.root = root
        self.interval = interval
    }

    deinit {
        task?.cancel()
    }

    /// Starts polling; `onChange` runs after each detected change, never concurrently.
    public func start(
        onChange: @escaping @Sendable () async -> Void
    ) {
        let root = root
        let interval = interval

        let task = Task {
            var last = Self.fingerprint(root)

            while !Task.isCancelled {
                try? await Task.sleep(for: interval)

                let next = Self.fingerprint(root)

                guard next != last else {
                    continue
                }

                last = next
                await onChange()
            }
        }

        lock.withLock {
            self.task?.cancel()
            self.task = task
        }
    }

    public func stop() {
        lock.withLock {
            task?.cancel()
            task = nil
        }
    }

    static func fingerprint(
        _ root: URL
    ) -> [String: String] {
        let files = (try? WebDirectoryFiles.list(root)) ?? []

        return Dictionary(
            files.map { ($0.relativePath, "\($0.modified.timeIntervalSince1970)-\($0.size)") },
            uniquingKeysWith: { first, _ in first }
        )
    }
}

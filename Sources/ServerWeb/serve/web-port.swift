import Foundation
#if canImport(Darwin)
import Darwin
#endif

public enum WebPortError: Error, LocalizedError {
    case socket(errno: Int32)
    case bind(errno: Int32)
    case inspect(errno: Int32)

    public var errorDescription: String? {
        switch self {
        case .socket(let code):
            return "Could not create probe socket: \(String(cString: strerror(code)))"
        case .bind(let code):
            return "Could not bind probe socket: \(String(cString: strerror(code)))"
        case .inspect(let code):
            return "Could not read probe socket port: \(String(cString: strerror(code)))"
        }
    }
}

public enum WebPort {
    /// Asks the kernel for a free TCP port on `host` by binding port 0.
    ///
    /// The probe socket is closed before the server binds, so another process
    /// could take the port in between. `ServerEngine` keeps its bound port
    /// `package`-scoped; exposing it would remove this race.
    public static func available(
        host: String = "127.0.0.1"
    ) throws -> UInt16 {
        let fd = socket(AF_INET, SOCK_STREAM, 0)

        guard fd >= 0 else {
            throw WebPortError.socket(errno: errno)
        }

        defer {
            close(fd)
        }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = 0
        address.sin_addr.s_addr = inet_addr(host)

        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bound == 0 else {
            throw WebPortError.bind(errno: errno)
        }

        var length = socklen_t(MemoryLayout<sockaddr_in>.size)

        let inspected = withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(fd, $0, &length)
            }
        }

        guard inspected == 0 else {
            throw WebPortError.inspect(errno: errno)
        }

        return UInt16(bigEndian: address.sin_port)
    }
}

import Foundation
import ServerWeb

struct DemoCommand {
    var host = "127.0.0.1"
    var port: UInt16?
    var browser = false
    var check = false
    var live = false

    static let usage = """
    USAGE: t_serverweb_demo [--browser] [--live] [--check] [--port <port>] [--host <host>]

    Builds a two-page site from typed data with the HTML/CSS/JS DSLs, plus a
    generated PNG, materializes it with Constructors (no files written) and
    serves it with ServerWeb.

      --browser, -b   Open the served URL in the default browser.
      --live, -l      Live reload: open pages reload when the demo restarts.
                      Use a fixed --port, edit, rebuild, rerun.
      --check         Fetch every path back, verify bytes, then exit (0 ok, 1 failed).
      --port, -p      Port to bind (default: a free port).
      --host          Host to bind (default: 127.0.0.1).
    """

    static func parse(
        _ arguments: [String]
    ) throws -> DemoCommand {
        var command = DemoCommand()
        var iterator = arguments.makeIterator()

        while let argument = iterator.next() {
            switch argument {
            case "--help", "-h":
                throw DemoCommandError.helpRequested

            case "--browser", "-b":
                command.browser = true

            case "--check":
                command.check = true

            case "--live", "-l":
                command.live = true

            case "--port", "-p":
                guard let value = iterator.next(),
                      let port = UInt16(value) else {
                    throw DemoCommandError.invalid("--port expects a number between 0 and 65535")
                }
                command.port = port

            case "--host":
                guard let value = iterator.next() else {
                    throw DemoCommandError.invalid("--host expects a value")
                }
                command.host = value

            default:
                throw DemoCommandError.invalid("Unexpected argument: \(argument)")
            }
        }

        return command
    }
}

enum DemoCommandError: Error, LocalizedError {
    case helpRequested
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .helpRequested:
            return DemoCommand.usage
        case .invalid(let message):
            return "\(message)\n\n\(DemoCommand.usage)"
        }
    }
}

@main
struct DemoMain {
    static func main() async {
        do {
            let command = try DemoCommand.parse(
                Array(CommandLine.arguments.dropFirst())
            )

            let site = try DemoSite.build()

            let server = WebServer(
                site: site,
                host: command.host,
                port: command.port,
                liveReload: command.live,
                logLevel: .error
            )

            let url = command.browser
                ? try await server.startAndOpen()
                : try await server.start()

            print("serving \(url.absoluteString)\(command.live ? " (live reload)" : "")")
            for asset in site.assets {
                print("  \(asset.path)  \(asset.contentType)")
            }

            if command.check {
                let lines = try await DemoCheck.run(site: site, url: url, liveReload: command.live)
                lines.forEach { print($0) }
                await server.stop()
                Foundation.exit(0)
            }

            print("ctrl-c to stop")

            switch try await server.waitForTermination() {
            case .stopped:
                Foundation.exit(0)
            case .failed(let message):
                printError(message)
                Foundation.exit(1)
            }
        } catch DemoCommandError.helpRequested {
            print(DemoCommand.usage)
            Foundation.exit(0)
        } catch let failure as DemoCheck.Failure {
            printError(failure.description)
            Foundation.exit(1)
        } catch {
            printError(error.localizedDescription)
            Foundation.exit(2)
        }
    }

    private static func printError(
        _ message: String
    ) {
        let text = message.hasSuffix("\n") ? message : "\(message)\n"

        FileHandle.standardError.write(
            Data(text.utf8)
        )
    }
}
